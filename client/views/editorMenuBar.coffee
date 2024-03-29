log = new Logger 'menuBar'

IconCmd = "&#8984;"
IconShift = "&#8679;"
IconOpt = "&#8997;"
Handlebars.registerHelper 'modKey', ->
  if Client.isMac
    "&#8984;"
  else
    "^"

Template.editorMenuBar.events
  'click #saveAction' : (event) ->
    return unless MadEye.editorState?.canSave()
    MadEye.editorState.save (err) ->
      if err
        #TODO: Handle error better.
        log.error "Error in save request:", err

  'click #revertAction': (event) ->
    return unless MadEye.editorState?.canRevert()
    MadEye.editorState.revertFile (err) ->
      if err
        #TODO: Handle error better.
        log.error "Error in revert request:", err

  'click #discardAction': (event) ->
    return unless MadEye.editorState?.canDiscard()
    file = Files.findOne MadEye.editorState.fileId
    return unless file and file.deletedInFs
    file.remove()
    MadEye.fileLoader.clearFile()

  'click .keybindingOption': (event) ->
    keybinding = event.target.dataset['keybinding']
    #ace is the default
    keybinding = null if 'ace' == keybinding
    Workspace.setConfig "keybinding", keybinding

  'click .fontsizeOption': (event) ->
    fontsize = parseInt event.target.dataset['fontsize'], 10
    Workspace.setConfig("fontSize", fontsize)

  'click .themeOption': (event) ->
    theme = event.target.dataset['theme']
    Workspace.setConfig "theme", theme

  'click #seeInvisibleAction': ->
    Workspace.setConfig "showInvisibles", !MadEye.editorState.editor.showInvisibles

  'click #wordWrapAction': ->
    Workspace.setConfig "wordWrap", !MadEye.editorState.editor.wordWrap

  'click #useSoftTabsAction': ->
    Workspace.setConfig "useSoftTabs", !MadEye.editorState.editor.useSoftTabs

  'click #enableSnippets': ->
    Workspace.setConfig 'enableSnippets', !MadEye.editorState.editor.enableSnippets

  'click .goAction': (event) ->
    action = goActions[this.id]
    action?.exec?()

  'click .editAction': (event) ->
    action = editActions[this.id]
    action?.exec?()

  'click .codeAction': (event) ->
    action = codeActions[this.id]
    action?.exec?()

Template.editorMenuBar.helpers
  saveDisabled: ->
    if MadEye.editorState?.canSave() then "" else " disabled "

  revertDisabled: ->
    if MadEye.editorState?.canRevert() then "" else " disabled "

  discardDisabled: ->
    if MadEye.editorState?.canDiscard() then "" else " disabled "

  toggleOptions: ->
    return [] unless MadEye.editorState?.editor?
    [
      {id:"seeInvisibleAction", name:"See Invisible", selected: MadEye.editorState.editor.showInvisibles}
      {id:"wordWrapAction", name:"Word Wrap", selected: MadEye.editorState.editor.wordWrap}
      {id:"useSoftTabsAction", name:"Use Soft Tabs", selected: MadEye.editorState.editor.useSoftTabs}
      {id:"enableSnippets", name:"Enable Snippets", selected: MadEye.editorState.editor.enableSnippets}
    ]

  goActions: ->
    findActions goActions, "goAction"

  editActions: ->
    findActions editActions, "editAction"

  codeActions: ->
    findActions codeActions, "codeAction"

  isMaximized: ->
    return Session.get 'fileOnly'

  maximizeLink: ->
    file = Files.findOne(MadEye.editorState?.fileId)
    "/file/#{Session.get 'projectId'}/#{file?.escapedPath}"

  minimizeLink: ->
    file = Files.findOne(MadEye.editorState?.fileId)
    "/edit/#{Session.get 'projectId'}/#{file?.escapedPath}"

findActions = (actionList, actionType) ->
  if Client.isMac
    key = 'mac'
  else
    key = 'pc'
  actions = []
  for id, action of actionList
    if action.break
      actions.push break:true
    else
      actions.push
        name:action.name
        actionType: actionType
        key:action[key]
        id:id
        disabled: action.disabled?() ? !action.exec
  return actions

getAceEditor = ->
 MadEye.editorState.getEditor()

editActions =
  'find':
    name: 'Find'
    pc: '^F'
    mac: "#{IconCmd}F"
    exec: ->
      require("ace/ext/searchbox").Search getAceEditor()

  'findnext':
    name: "Find Next",
    pc: '^K'
    mac: "#{IconCmd}G"
    exec: -> getAceEditor().findNext()

  "findprevious":
    name: "Find Previous",
    pc: "^#{IconShift}K"
    mac: "#{IconCmd}#{IconShift}G"
    exec: -> getAceEditor().findPrevious()

  'replace':
    name: "Replace",
    pc: '^H'
    mac: "#{IconCmd}#{IconOpt}F"
    exec: ->
      require("ace/ext/searchbox").Search getAceEditor(), true

  'break1' :
    break : true

  "removeline":
    name: "Remove Line",
    pc: '^D'
    mac: "#{IconCmd}D"
    exec: -> getAceEditor().removeLines()

  "togglecomment":
    name: "Toggle Comment",
    pc: "^/"
    mac: "#{IconCmd}/"
    exec: -> getAceEditor().toggleCommentLines()

  "toggleBlockComment":
    name: "Toggle Block Comment",
    pc: "^#{IconShift}/"
    mac: "#{IconCmd}/#{IconShift}"
    exec: -> getAceEditor().toggleBlockComment()

  "indent":
    name: "Indent",
    pc: 'Tab'
    mac: 'Tab'
    exec: -> getAceEditor().indent()

  "outdent":
    name: "Outdent",
    pc: "#{IconShift}Tab"
    mac: "#{IconShift}Tab"
    exec: -> getAceEditor().blockOutdent()

  "blockindent":
    name: "Block Indent",
    pc: "^]"
    mac: "^]"
    exec: -> getAceEditor().blockIndent()

  "blockoutdent":
    name: "Block Outdent",
    pc: "^["
    mac: "^["
    exec: -> getAceEditor().blockOutdent()

  'break2' :
    break : true

  "undo":
    name: "Undo",
    pc: "^Z"
    mac: "#{IconCmd}Z"
    exec: -> getAceEditor().undo()

  "redo":
    name: "Redo",
    pc: "^#{IconShift}Z" #TODO: Also ^Y
    mac: "#{IconCmd}#{IconShift}Z" #TODO: Also Cmd-Shift-Y
    exec: -> getAceEditor().redo()

#TODO: These duplicate some data in ace/default_conmands.js
#Source from there some how?
goActions =
  'gotoLine':
    name: "Goto line"
    pc: "^L"
    mac: "#{IconCmd}L"
    exec: ->
      line = parseInt(prompt("Enter line number:"), 10)
      getAceEditor().gotoLine(line) unless isNaN(line)

  'centerSelection':
    name: 'Center Selection',
    mac: "^L"
    exec: -> getAceEditor().centerSelection()

  'jumpToMatching':
    name: 'Jump to Matching Bracket'
    pc: '^P'
    mac: "^#{IconShift}P"
    exec: -> getAceEditor().jumpToMatching()

  "selectToMatching":
    name: "Select to Matching Bracket",
    pc: "^#{IconShift}P"
    exec: -> getAceEditor().jumpToMatching(true)

codeActions =
  completeKeyword:
    name: "Complete Keyword"
    pc: '^-Space'
    mac: '^-Space'
    exec: ->
      editor = getAceEditor()
      editor.commands.byName['startAutocomplete'].exec editor

  expandSnippet:
    name: "Expand Snippet"
    pc: "Tab"
    mac: "Tab"
    disabled: ->
      !MadEye.editorState?.editor.enableSnippets
    exec: ->
      MadEye.editorState.snippetManager.expandWithTab(getAceEditor())

  break :
    break : true

  toggleFold:
    name: "Toggle Fold"
    pc: "F2"
    mac: "F2"
    exec: ->
      getAceEditor().session.toggleFoldWidget()

  foldAll:
    name: "Fold All"
    pc: "^Alt-0"
    mac: "^#{IconOpt}#{IconCmd}0"
    exec: ->
      getAceEditor().session.foldAll()

  foldOther:
    name: "Fold Other"
    pc: "Alt-0"
    mac: "#{IconOpt}#{IconCmd}0"
    exec: ->
      getAceEditor().session.foldAll()
      getAceEditor().session.unfold(getAceEditor().selection.getAllRanges())
      getAceEditor().centerSelection()

  unfoldAll:
    name: "Unfold All"
    pc: "Alt-#{IconShift}0"
    mac: "#{IconShift}#{IconOpt}#{IconCmd}0"
    exec: ->
      getAceEditor().session.unfold()
      getAceEditor().centerSelection()
