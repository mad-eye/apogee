#editor.setShowInvisibles()
#editor.setMode()
#editor.setTheme()
#editor.setKeyboardHandler()


inputs = {
  'themeSelect': 'eclipse'
  'modeSelect': null
  'showInvisibles': false
  'keyboardSelect': 'ace'
}

Template.editorBar.events
  'click #runButton': (e)->
    editorBody = editorState.getEditor().getValue()
    $("#stdout").find(".filler").remove()
    $("#stdout").prepend('<div id="codeExecutingSpinner"><img src="/images/file-loader.gif" alt="Loading..." />\n</div>')
    Meteor.http.post "#{Meteor.settings.public.nurmengardUrl}/run", {data: {contents: editorBody, language: Session.get "syntaxMode"}, headers: {"Content-Type":"application/json"}}, (error, result)->
      $("#codeExecutingSpinner").remove()
      if error
        console.error "MADEYE ERROR", error
      if result
        response = JSON.parse(result.content)
        $("#stdout").prepend("<span class='stderr'>#{response.stderr}</span>\n") if response.stderr
        $("#stdout").prepend("<span class='stdout'>#{response.stdout}</span>\n") if response.stdout
        $("#stdout").prepend("<span class='runError'>RUN ERROR: #{response.runError}</span>\n") if response.runError

  'change #wordWrap': (e) ->
    Session.set 'wordWrap', e.srcElement.checked

  'change #showInvisibles': (e) ->
    Session.set 'showInvisibles', e.srcElement.checked

  'change #syntaxModeSelect': (e) ->
    Session.set 'syntaxMode', e.srcElement.value

  'change #keybinding': (e) ->
    keybinding = e.srcElement.value
    keybinding = null if 'ace' == keybinding
    Session.set 'keybinding', keybinding

  'change #themeSelect': (e) ->
    Session.set 'theme', e.srcElement.value

  'change #useSoftTabs': (e) ->
    editorState.useSoftTabs = e.srcElement.checked

  'change #tabSize': (e) ->
    editorState.tabSize = parseInt e.srcElement.value

  'click #revertFile': (event) ->
    el = $(event.target)
    return if el.hasClass 'disabled' or Session.get 'working'
    Session.set "working", true
    editorState.revertFile (error)->
      Session.set "working", false

  'click #discardFile': (event) ->
    Metrics.add
      message:'discardFile'
      fileId: editorState?.file?._id
      filePath: editorState?.file?.path #don't want reactivity
    editorState.file.remove()
    editorState.file = null
    editorState.setPath ""

  'click #saveImage' : (event) ->
    el = $(event.target)
    return if el.hasClass 'disabled' or Session.get 'working'
    console.log "clicked save button"
    Session.set "working", true
    editorState.save (err) ->
      if err
        #Handle error better.
        console.error "Error in save request:", err
      Session.set "working", false

Template.editorBar.rendered = ->
  Session.set 'editorBarRendered', true

Template.editorBar.helpers
  editorState: ->
    editorState

  tabSizeEquals: (size)->
    return false unless editorState.isRendered
    editorState?.tabSize == parseInt size

  showSaveSpinner: ->
    Session.equals "working", true

  buttonDisabled : ->
    filePath = editorState.getPath()
    file = Files.findOne({path: filePath}) if filePath?
    if !file?.modified or Session.equals("working", true) or projectIsClosed()
      "disabled"
    else
      ""

  runButtonDisabled: ->
    project = Projects.findOne(Session.get("projectId"))
    disabled = "disabled"
    if Session.get("syntaxMode") in ["javascript", "python", "ruby", "coffee"]
      disabled = ""
    return disabled

  isHangout: ->
    Session.get "isHangout"


Template.syntaxModeOptions.helpers
  #XXX: Clean this and MadEye.ACE_MODES up, into one structure.
  'syntaxModes': ->
    [
      {value:"abap", name:"ABAP"},
      {value:"asciidoc", name:"AsciiDoc"},
      {value:"c9search", name:"C9Search"},
      {value:"coffee", name:"CoffeeScript"},
      {value:"coldfusion", name:"ColdFusion"},
      {value:"csharp", name:"C#"},
      {value:"css", name:"CSS"},
      {value:"curly", name:"Curly"},
      {value:"dart", name:"Dart"},
      {value:"diff", name:"Diff"},
      {value:"dot", name:"Dot"},
      {value:"ftl", name:"FreeMarker"},
      {value:"glsl", name:"Glsl"},
      {value:"golang", name:"Go"},
      {value:"groovy", name:"Groovy"},
      {value:"haxe", name:"haXe"},
      {value:"haml", name:"HAML"},
      {value:"html", name:"HTML"},
      {value:"c_cpp", name:"C/C++"},
      {value:"clojure", name:"Clojure"},
      {value:"jade", name:"Jade"},
      {value:"java", name:"Java"},
      {value:"jsp", name:"JSP"},
      {value:"javascript", name:"JavaScript"},
      {value:"json", name:"JSON"},
      {value:"jsx", name:"JSX"},
      {value:"latex", name:"LaTeX"},
      {value:"less", name:"LESS"},
      {value:"lisp", name:"Lisp"},
      {value:"scheme", name:"Scheme"},
      {value:"liquid", name:"Liquid"},
      {value:"livescript", name:"LiveScript"},
      {value:"logiql", name:"LogiQL"},
      {value:"lua", name:"Lua"},
      {value:"luapage", name:"LuaPage"},
      {value:"lucene", name:"Lucene"},
      {value:"lsl", name:"LSL"},
      {value:"makefile", name:"Makefile"},
      {value:"markdown", name:"Markdown"},
      {value:"objectivec", name:"Objective-C"},
      {value:"ocaml", name:"OCaml"},
      {value:"pascal", name:"Pascal"},
      {value:"perl", name:"Perl"},
      {value:"pgsql", name:"pgSQL"},
      {value:"php", name:"PHP"},
      {value:"powershell", name:"Powershell"},
      {value:"python", name:"Python"},
      {value:"r", name:"R"},
      {value:"rdoc", name:"RDoc"},
      {value:"rhtml", name:"RHTML"},
      {value:"ruby", name:"Ruby"},
      {value:"scad", name:"OpenSCAD"},
      {value:"scala", name:"Scala"},
      {value:"scss", name:"SCSS"},
      {value:"sass", name:"SASS"},
      {value:"sh", name:"SH"},
      {value:"sql", name:"SQL"},
      {value:"stylus", name:"Stylus"},
      {value:"svg", name:"SVG"},
      {value:"tcl", name:"Tcl"},
      {value:"tex", name:"Tex"},
      {value:"text", name:"Text"},
      {value:"textile", name:"Textile"},
      {value:"tm_snippet", name:"tmSnippet"},
      {value:"toml", name:"toml"},
      {value:"typescript", name:"Typescript"},
      {value:"vbscript", name:"VBScript"},
      {value:"xml", name:"XML"},
      {value:"xquery", name:"XQuery"},
      {value:"yaml", name:"YAML"}
    ]

Template.themeOptions.helpers
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

  #Word Wrap
  Deps.autorun ->
    return unless Session.equals("editorRendered", true)
    #Need to do editorState.getEditor().getSession().setWrapLimitRange(min, max) somewhere
    #Ideally tied to editor size
    session = editorState.getEditor().getSession()
    editorState.getEditor().renderer.setPrintMarginColumn 80
    if Session.get 'wordWrap'
      session.setUseWrapMode true
      session.setWrapLimitRange null, null
    else
      session.setUseWrapMode false

  #Show Invisibles
  Deps.autorun ->
    return unless Session.equals("editorRendered", true)
    editorState.getEditor().setShowInvisibles Session.get 'showInvisibles' ? false

  #Syntax Modes from session
  Deps.autorun (computation) ->
    return unless Session.equals("editorRendered", true)
    mode = Session.get 'syntaxMode'
    editorSession = editorState.getEditor().getSession()
    unless mode?
      return editorSession?.setMode null
    module = require("ace/mode/#{mode}")
    unless module
      jQuery.getScript("/ace/mode-#{mode}.js").done( ->
        return computation.invalidate()
      ).fail(->
        editorSession?.setMode null
      )
    else
      Mode = module.Mode
      editorSession?.setMode(new Mode())

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
    file = Files.findOne(path: editorState.getPath()) or ScratchPads.findOne(path: editorState.getPath())
    return unless file
    mode = file.aceMode
    #Check for shebang. We might have such lines as '#! /bin/env sh -x'
    unless mode
      cmd = findShbangCmd editorState.getEditorBody()
      mode = switch cmd
        when 'sh', 'ksh', 'csh', 'tcsh', 'bash', 'dash', 'zsh' then 'sh'
        when 'node' then 'javascript'
        #Other aliases?
        else cmd
      mode = null unless mode in _.values(MadEye.ACE_MODES)
    Session.set 'syntaxMode', mode

  #Keybinding
  Deps.autorun (computation) ->
    return unless Session.equals("editorRendered", true)
    keybinding = Session.get 'keybinding'
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

  #Theme
  Deps.autorun ->
    return unless Session.equals("editorRendered", true)
    theme = Session.get 'theme'
    return unless theme
    editorState.getEditor().setTheme("ace/theme/"+theme)
