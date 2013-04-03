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


Template.aceBar.events
  'change #showInvisibles': (e) ->
    Session.set 'showInvisibles', e.srcElement.checked

  'change #fileModeSelect': (e) ->
    Session.set 'fileMode', e.srcElement.value

  'change #keybinding': (e) ->
    console.log "Changing keybinding to ", e.srcElement.value
    Session.set 'keybinding', e.srcElement.value

  'change #themeSelect': (e) ->
    Session.set 'theme', e.srcElement.value

Template.aceBar.helpers
  'showInvisibles': ->
    Session.get 'showInvisibles' ? false

Template.aceBar.rendered = ->
  Session.set 'aceBarRendered', true


Template.fileModeOptions.helpers
  'fileModes': ->
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

  'isFileModeActive': (mode) ->
    Session.equals 'fileMode', mode

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

  isThemeActive: (theme) ->
    Session.equals 'theme', theme

Meteor.startup ->

  Deps.autorun ->
    editorState.getEditor().setShowInvisibles Session.get 'showInvisibles' ? false

  Deps.autorun ->
    mode = Session.get 'fileMode'
    return unless mode?
    editorSession = editorState.getEditor().getSession()
    Mode = undefined
    try
      Mode = require("ace/mode/#{mode}").Mode
      editorSession?.setMode(new Mode())
    catch e
      jQuery.getScript "/ace/mode-#{mode}.js", =>
        Mode = require("ace/mode/#{mode}").Mode
        editorSession?.setMode(new Mode())

  Deps.autorun ->
    file = Files.findOne path: editorState.getPath()
    Session.set 'fileMode', file.aceMode() if file?.aceMode()

  Deps.autorun ->
    keybinding = Session.get 'keybinding'
    return unless keybinding
    if 'ace' == keybinding
      #'ace' was in the examples, but the method only takes null, 'vim', or 'emacs'
      keybinding = null
    console.log "Setting keybinding", keybinding
    editorState.getEditor().setKeyboardHandler keybinding


  Deps.autorun ->
    theme = Session.get 'theme'
    return unless theme
    editorState.getEditor().setTheme("ace/theme/"+theme)
