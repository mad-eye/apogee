log = new MadEye.Logger 'editorBar'
aceModes = ace.require('ace/ext/modelist')

@getWorkspace = ->
  Workspaces.findOne {userId: Meteor.userId()}

setWorkspaceConfig = (key, value)->
  workspace = getWorkspace()
  return unless workspace
  workspace[key] = value
  workspace.save()

addWorkspaceModeOverride = (fileId, syntaxMode) ->
  workspace = getWorkspace()
  return unless workspace
  workspace.modeOverrides ?= {}
  workspace.modeOverrides[fileId] = syntaxMode
  workspace.save()


Template.editorBar.events
  'click #runButton': (e)->
    Session.set "codeExecuting", true
    editorBody = MadEye.editorState.getEditor().getValue()
    filename = MadEye.fileLoader.editorFilePath
    Meteor.http.post "#{Meteor.settings.public.nurmengardUrl}/run",
      data:
        contents: editorBody
        language: MadEye.editorState.editor.syntaxMode
        fileName: filename
      headers:
        "Content-Type": "application/json"
      , (error, result)->
        Session.set "codeExecuting", false
        if error
          #TODO handle this better
          console.error "MADEYE ERROR", error
        if result
          response = JSON.parse(result.content)
          response.filename = filename
          response.projectId = Session.get("projectId")
          response.timestamp = Date.now()
          ScriptOutputs.insert response

  'click #revertFile': (event) ->
    el = $(event.target)
    return if el.hasClass 'disabled' or MadEye.editorState.working == true
    MadEye.editorState.revertFile (error)->

  'click #discardFile': (event) ->
    file = Files.findOne MadEye.editorState.fileId
    return unless file and file.deletedInFs
    Metrics.add
      message:'discardFile'
      fileId: file._id
      filePath: file.path
    file.remove()
    MadEye.fileLoader.clearFile()

  'click #saveImage' : (event) ->
    el = $(event.target)
    return if el.hasClass 'disabled' or MadEye.editorState.working == true
    MadEye.editorState.save (err) ->
      if err
        #Handle error better.
        console.error "Error in save request:", err

Template.editorBar.helpers
  "editorFileName": ->
    MadEye.fileLoader?.editorFilePath

  showSaveSpinner: ->
    MadEye.editorState.working == true

  buttonDisabled : ->
    fileId = MadEye.editorState?.fileId
    file = Files.findOne(fileId) if fileId?
    if !file?.modified or MadEye.editorState.working==true or projectIsClosed()
      "disabled"
    else
      ""

  runButtonDisabled: ->
    project = Projects.findOne(Session.get("projectId"))
    disabled = "disabled"
    if canRunLanguage MadEye.editorState.editor.syntaxMode
      disabled = ""
    return disabled

  isHangout: ->
    Session.get "isHangout"

Template.statusBar.created = ->
  MadEye.rendered 'statusBar'

Template.statusBar.rendered = ->
  outputOffset = if isInterview() then $('#programOutput').height() else 0
  $('#statusBar').css 'bottom', outputOffset
  resizeEditor()

Template.editorBar.created = ->
  MadEye.rendered 'editorBar'

Template.editorBar.rendered = ->
  resizeEditor()

Template.statusBar.events
  'change #wordWrap': (e) ->
    setWorkspaceConfig "wordWrap", e.target.checked

  'change #showInvisibles': (e) ->
    setWorkspaceConfig "showInvisibles", e.target.checked

  'change #syntaxModeSelect': (e) ->
    addWorkspaceModeOverride MadEye.editorState.fileId, e.target.value

  'change #useSoftTabs': (e) ->
    setWorkspaceConfig "useSoftTabs", e.target.checked

  'change #tabSize': (e) ->
    setWorkspaceConfig("tabSize", parseInt(e.target.value, 10))

  'change #keybinding': (e) ->
    keybinding = e.target.value
    keybinding = null if 'ace' == keybinding
    setWorkspaceConfig "keybinding", keybinding

  'change #themeSelect': (e) ->
    setWorkspaceConfig "theme", e.target.value

Template.statusBar.helpers
  editorState: ->
    MadEye.editorState

  tabSizeEquals: (size)->
    return false unless MadEye.editorState.rendered
    MadEye.editorState?.editor.tabSize == parseInt size, 10

  keybinding: (binding)->
    keybinding = getWorkspace()?.keybinding
    keybinding == binding

Template.syntaxModeOptions.helpers
  selected: (value) ->
    "selected" if MadEye.editorState.editor.syntaxMode == @name

  syntaxModes: ->
    aceModes.modes

  canRunLanguage: (language) ->
    isInterview() && canRunLanguage language

Template.themeOptions.helpers
  themeEquals: (value) ->
    MadEye.editorState.editor.theme == value

  brightThemes: ->
    [
      {value: "chrome", name: "Chrome"},
      {value: "clouds", name: "Clouds"},
      {value: "crimson_editor", name: "Crimson Editor"},
      {value: "dawn", name: "Dawn"},
      {value: "dreamweaver", name: "Dreamweaver"},
      {value: "eclipse", name: "Eclipse"},
      {value: "github", name: "GitHub"},
      {value: "solarized_light", name: "Solarized Light"},
      {value: "textmate", name: "TextMate"},
      {value: "tomorrow", name: "Tomorrow"},
      {value: "xcode", name: "XCode"}
    ]

  darkThemes: ->
    [
      {value: "ambiance", name: "Ambiance"},
      {value: "chaos", name: "Chaos"},
      {value: "clouds_midnight", name: "Clouds Midnight"},
      {value: "cobalt", name: "Cobalt"},
      {value: "idle_fingers", name: "idleFingers"},
      {value: "kr_theme", name: "krTheme"},
      {value: "merbivore", name: "Merbivore"},
      {value: "merbivore_soft", name: "Merbivore Soft"},
      {value: "mono_industrial", name: "Mono Industrial"},
      {value: "monokai", name: "Monokai"},
      {value: "pastel_on_dark", name: "Pastel on dark"},
      {value: "solarized_dark", name: "Solarized Dark"},
      {value: "terminal", name: "Terminal"},
      {value: "tomorrow_night", name: "Tomorrow Night"},
      {value: "tomorrow_night_blue", name: "Tomorrow Night Blue"},
      {value: "tomorrow_night_bright", name: "Tomorrow Night Bright"},
      {value: "tomorrow_night_eighties", name: "Tomorrow Night 80s"},
      {value: "twilight", name: "Twilight"},
      {value: "vibrant_ink", name: "Vibrant Ink"}
    ]

Meteor.startup ->

  findShbangCmd = (contents) ->
    if '#!' == contents[0..1]
      cmd = null
      firstLine = contents.split('\n', 1)[0]
      #trim and split tokens on whitespace
      tokens = (firstLine[2..]).replace(/^\s+|\s+$/g,'').split(/\s+/)
      token = tokens.pop()
      while token
        unless '-' == token[0]
          index = token.lastIndexOf '/'
          cmd = token[index+1..]
          break
        token = tokens.pop()
      return cmd

  #Syntax Modes from file
  Deps.autorun ->
    return unless MadEye.isRendered 'editor'
    file = Files.findOne(MadEye.editorState?.fileId)
    return unless file
    workspace = Workspaces.findOne {userId: Meteor.userId()}
    if workspace?.modeOverrides?[MadEye.editorState.fileId]
      MadEye.editorState.editor.syntaxMode = workspace.modeOverrides[MadEye.editorState.fileId]
      return
    mode = file.aceMode
    #Check for shebang. We might have such lines as '#! /bin/env sh -x'
    unless mode
      cmd = findShbangCmd MadEye.editorState.editor.value
      mode = switch cmd
        when 'sh', 'ksh', 'csh', 'tcsh', 'bash', 'dash', 'zsh' then 'sh'
        when 'node' then 'javascript'
        #Other aliases?
        else cmd
      log.trace "Found mode #{mode} from shbang command #{cmd}"
      mode = null unless mode in _.keys(aceModes.modesByName)
    MadEye.editorState.editor.syntaxMode = mode

  #Keybinding
  Deps.autorun (computation) ->
    return unless MadEye.isRendered('editor') and MadEye.editorState
    workspace = getWorkspace()
    return unless workspace
    keybinding = workspace.keybinding
    unless keybinding
      #No keybinding means Ace
      MadEye.editorState.getEditor().setKeyboardHandler null
    else
      module = require("ace/keyboard/#{keybinding}")
      unless module
        jQuery.getScript "/ace/keybinding-#{keybinding}.js", ->
          computation.invalidate()
      else
        handler = module.handler
        MadEye.editorState.getEditor().setKeyboardHandler handler

  Deps.autorun (computation) ->
    return unless MadEye.isRendered('editor') and MadEye.editorState
    workspace = getWorkspace()
    return unless workspace
    MadEye.editorState.editor.showInvisibles = workspace.showInvisibles
    MadEye.editorState.editor.tabSize = workspace.tabSize
    MadEye.editorState.editor.theme = workspace.theme
    MadEye.editorState.editor.useSoftTabs = workspace.useSoftTabs
    MadEye.editorState.editor.wordWrap = workspace.wordWrap
