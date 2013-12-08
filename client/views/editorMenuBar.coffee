Handlebars.registerHelper 'modKey', ->
  if Client.isMac
    "&#8984;"
  else
    "^"

Template.editorMenuBar.events
  'click #saveAction' : (event) ->
    console.log "ZZZ: Save"
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

Template.editorMenuBar.helpers
  saveDisabled: ->
    if MadEye.editorState?.canSave() then "" else " disabled "

  revertDisabled: ->
    if MadEye.editorState?.canRevert() then "" else " disabled "

  discardDisabled: ->
    if MadEye.editorState?.canDiscard() then "" else " disabled "

