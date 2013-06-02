getWorkspace = ->
  Workspaces.findOne {userId: Meteor.userId()}

setWorkspaceConfig = (key, value)->
  workspace = getWorkspace()
  workspace ?= new MadEye.Workspace(userId: Meteor.userId())
  workspace[key] = value
  workspace.save()

addWorkspaceModeOverride = (fileId, syntaxMode) ->
  workspace = getWorkspace()
  workspace ?= new MadEye.Workspace(userId: Meteor.userId())
  workspace.modeOverrides ?= {}
  workspace.modeOverrides[fileId] = syntaxMode
  workspace.save()


Template.editorBar.events
  'click #runButton': (e)->
    Session.set "codeExecuting", true
    editorBody = editorState.getEditor().getValue()
    filename = MadEye.fileLoader.editorFilePath
    Meteor.http.post "#{Meteor.settings.public.nurmengardUrl}/run",
      data:
        contents: editorBody
        language: editorState.editor.syntaxMode
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

  'change #keybinding': (e) ->
    keybinding = e.target.value
    keybinding = null if 'ace' == keybinding
    setWorkspaceConfig "keybinding", keybinding

  'change #themeSelect': (e) ->
    setWorkspaceConfig "theme", e.target.value

  'click #revertFile': (event) ->
    el = $(event.target)
    return if el.hasClass 'disabled' or editorState.working == true
    editorState.revertFile (error)->

  'click #discardFile': (event) ->
    file = Files.findOne editorState.fileId
    return unless file
    Metrics.add
      message:'discardFile'
      fileId: file._id
      filePath: file.path
    file.remove()
    MadEye.fileLoader.loadPath = ""
    #XXX: This will eventually not be necessary.
    editorState.fileId = null

  'click #saveImage' : (event) ->
    el = $(event.target)
    return if el.hasClass 'disabled' or editorState.working == true
    console.log "clicked save button"
    editorState.save (err) ->
      if err
        #Handle error better.
        console.error "Error in save request:", err

Template.editorBar.helpers
  "editorFileName": ->
    MadEye.fileLoader?.editorFilePath

Template.editorBar.rendered = ->
  Session.set 'editorBarRendered', true

Template.statusBar.events
  'change #wordWrap': (e) ->
    setWorkspaceConfig "wordWrap", e.target.checked

  'change #showInvisibles': (e) ->
    setWorkspaceConfig "showInvisibles", e.target.checked

  'change #syntaxModeSelect': (e) ->
    addWorkspaceModeOverride editorState.fileId, e.target.value

  'change #useSoftTabs': (e) ->
    setWorkspaceConfig "useSoftTabs", e.target.checked

  'change #tabSize': (e) ->
    setWorkspaceConfig("tabSize", parseInt(e.target.value, 10))

Template.statusBar.helpers
  editorState: ->
    editorState

  tabSizeEquals: (size)->
    return false unless editorState.rendered
    editorState?.editor.tabSize == parseInt size, 10

  showSaveSpinner: ->
    editorState.working == true

  buttonDisabled : ->
    fileId = editorState.fileId
    file = Files.findOne(fileId) if fileId?
    if !file?.modified or editorState.working==true or projectIsClosed()
      "disabled"
    else
      ""

  runButtonDisabled: ->
    project = Projects.findOne(Session.get("projectId"))
    disabled = "disabled"
    if canRunLanguage editorState.editor.syntaxMode
      disabled = ""
    return disabled

  isHangout: ->
    Session.get "isHangout"

  keybinding: (binding)->
    keybinding = getWorkspace()?.keybinding
    keybinding == binding

#XXX: Clean this and MadEye.ACE_MODES up, into one structure.
@syntaxModes =
  abap : "ABAP"
  asciidoc : "AsciiDoc"
  c9search : "C9Search"
  coffee : "CoffeeScript"
  coldfusion : "ColdFusion"
  csharp : "C#"
  css : "CSS"
  curly : "Curly"
  dart : "Dart"
  diff : "Diff"
  dot : "Dot"
  ftl : "FreeMarker"
  glsl : "Glsl"
  golang : "Go"
  groovy : "Groovy"
  haxe : "haXe"
  haml : "HAML"
  html : "HTML"
  c_cpp : "C/C++"
  clojure : "Clojure"
  jade : "Jade"
  java : "Java"
  jsp : "JSP"
  javascript : "JavaScript"
  json : "JSON"
  jsx : "JSX"
  latex : "LaTeX"
  less : "LESS"
  lisp : "Lisp"
  scheme : "Scheme"
  liquid : "Liquid"
  livescript : "LiveScript"
  logiql : "LogiQL"
  lua : "Lua"
  luapage : "LuaPage"
  lucene : "Lucene"
  lsl : "LSL"
  makefile : "Makefile"
  markdown : "Markdown"
  objectivec : "Objective-C"
  ocaml : "OCaml"
  pascal : "Pascal"
  perl : "Perl"
  pgsql : "pgSQL"
  php : "PHP"
  powershell : "Powershell"
  python : "Python"
  r : "R"
  rdoc : "RDoc"
  rhtml : "RHTML"
  ruby : "Ruby"
  scad : "OpenSCAD"
  scala : "Scala"
  scss : "SCSS"
  sass : "SASS"
  sh : "SH"
  sql : "SQL"
  stylus : "Stylus"
  svg : "SVG"
  tcl : "Tcl"
  tex : "Tex"
  text : "Text"
  textile : "Textile"
  tm_snippet : "tmSnippet"
  toml : "toml"
  typescript : "Typescript"
  vbscript : "VBScript"
  xml : "XML"
  xquery : "XQuery"
  yaml : "YAML"

Template.syntaxModeOptions.helpers
  syntaxModeEquals: (value) ->
    editorState.editor.syntaxMode == value

  #XXX: The map seems to be traversed 'in order', but we shouldn't rely on that.
  syntaxModes: ->
    ({value:handle, name:name} for handle, name of syntaxModes)

  canRunLanguage: (language) ->
    isInterview() && canRunLanguage language

Template.themeOptions.helpers
  themeEquals: (value) ->
    editorState.editor.theme == value

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
      {value: "twilight", name: "Twilight"},
      {value: "tomorrow_night", name: "Tomorrow Night"},
      {value: "tomorrow_night_blue", name: "Tomorrow Night Blue"},
      {value: "tomorrow_night_bright", name: "Tomorrow Night Bright"},
      {value: "tomorrow_night_eighties", name: "Tomorrow Night 80s"},
      {value: "vibrant_ink", name: "Vibrant Ink"}
    ]

Meteor.startup ->

  findShbangCmd = (contents) ->
    if '#!' == contents[0..1]
      cmd = null
      firstLine = contents.split('\n', 1)[0]
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
    return unless Session.equals("editorRendered", true)
    file = Files.findOne(editorState.fileId)
    return unless file
    workspace = Workspaces.findOne {userId: Meteor.userId()}
    if workspace?.modeOverrides?[editorState.fileId]
      editorState.editor.syntaxMode = workspace.modeOverrides[editorState.fileId]
      return
    mode = file.aceMode
    #Check for shebang. We might have such lines as '#! /bin/env sh -x'
    unless mode
      cmd = findShbangCmd editorState.editor.value
      mode = switch cmd
        when 'sh', 'ksh', 'csh', 'tcsh', 'bash', 'dash', 'zsh' then 'sh'
        when 'node' then 'javascript'
        #Other aliases?
        else cmd
      mode = null unless mode in _.values(MadEye.ACE_MODES)
    editorState.editor.syntaxMode = mode

  #Keybinding
  Deps.autorun (computation) ->
    return unless Session.equals("editorRendered", true)
    workspace = getWorkspace()
    return unless workspace
    keybinding = workspace.keybinding
    unless keybinding
      #No keybinding means Ace
      editorState.getEditor().setKeyboardHandler null
    else
      module = require("ace/keyboard/#{keybinding}")
      unless module
        jQuery.getScript "/ace/keybinding-#{keybinding}.js", ->
          computation.invalidate()
      else
        handler = module.handler
        editorState.getEditor().setKeyboardHandler handler

  Deps.autorun (computation) ->
    return unless Session.equals("editorRendered", true)
    workspace = getWorkspace()
    return unless workspace
    editorState.editor.showInvisibles = workspace.showInvisibles
    editorState.editor.tabSize = workspace.tabSize
    editorState.editor.theme = workspace.theme
    editorState.editor.useSoftTabs = workspace.useSoftTabs
    editorState.editor.wordWrap = workspace.wordWrap
