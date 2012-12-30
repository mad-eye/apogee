# TODO Eliminate need to wrap this in do ->
# https://github.com/meteor/meteor/pull/85

do ->
  makeNetworkError = (result) ->
    return null unless result?
    error = JSON.parse(result?.content)?.error
    error ?=
      type: result.statusCode
      message: result.error?.message
    error.title = error.type #TODO: for now.  Eventually make it more understandable
    error.level = 'error'
    console.log "Made error", error
    return error

  handleNetworkError = (error, result) ->
    displayAlert makeNetworkError(result) ? { level: 'error', message: error.message }

  fileTree = new Madeye.FileTree()

  projectIsOpen = ->
    Projects.findOne()?.opened

  Template.projectStatus.projectIsOpen = ->
    projectIsOpen()

  Template.projectStatus.projectClosedError = ->
    level: 'error'
    title: 'Project Closed'
    message: 'The project has been closed on the client.'
    uncloseable: true


  Template.fileTree.files = ->
    fileTree.setFiles Files.collection.find()
    _.filter fileTree.files, (file)->
      fileTree.isVisible(file)

  Template.fileTree.fileEntryClass = ->
    clazz = "fileTree-item"
    if @isDir
      clazz += " directory " + if @isOpen() then "open" else "closed"
    else
      clazz += " file"
    clazz += " level" + this.depth
    clazz += " selected" if this.isSelected()
    return clazz

  Template.fileTree.projectName = ->
    Projects.findOne()?.name ? "New project"

  # Select file
  Template.fileTree.events
    'click li.fileTree-item' : (event) ->
      fileId = event.currentTarget.id
      file = fileTree.findById fileId
      file.select()

  fileUrl = (fileId)->
    settings = Settings.findOne()
    url = "http://#{settings.httpHost}:#{settings.httpPort}"
    url = "#{url}/project/#{Projects.findOne()._id}/file/#{fileId}"
    console.log url
    url

  fetchBody = (fileId, callback) ->
    console.log "fetching body"
    Meteor.http.get fileUrl(fileId), (error,result)->
      if error
        handleNetworkError error, result
      else
        callback JSON.parse(result.content).body

  getEditorBody = ->
    ace.edit("editor")?.getValue()

  save = (fileId)->
    contents = getEditorBody()
    file = Files.findOne fileId
    return unless file.modified
    Meteor.http.call "PUT", fileUrl(fileId), {
      data: {contents: contents}
      headers: {'Content-Type':'application/json'}
    }, (error,result)->
      if error
        handleNetworkError error, result
      else
        #XXX: Are we worried about race conditions if there were modifications after the save button was pressed?
        file.update {modified: false}

  Template.editor.preserve("#editor")

  Template.editor.rendered = ->
    Session.set("editorRendered", true)

  editorState = null
  Meteor.startup ->
    editorState = new EditorState

  Meteor.autorun ->
    console.log "AUTORUN"
    return unless Session.equals("editorRendered", true)
    return if Session.equals "editorFileId", editorState?.file?._id
    settings = Settings.findOne()
    file = Files.findOne {_id: Session.get "editorFileId"}
    return unless file
    editorState.file = file
    editor = ace.edit("editor")
    #TODO: Switch to using sharejs.openExisting
    #XXX this relies on a custom hacked version of sharejs.open that is not the same
    #    as the one documented on the sharejs website
    sharejs.open file._id, 'text', "http://#{settings.bolideHost}:#{settings.bolidePort}/channel", (error, doc) ->
      if mode = file.aceMode()
        jQuery.getScript "/ace/mode-#{mode}.js", =>
          Mode = require("ace/mode/#{mode}").Mode
          editor.getSession().setMode(new Mode())

      if doc?
        doc.attach_ace editor
        doc.on 'change', (op) ->
          file.update {modified: true}
      else
        console.log "docless"
        fetchBody file._id, (body)->
          if body?
            sharejs.open file._id, 'text', "http://#{settings.bolideHost}:#{settings.bolidePort}/channel", (error, doc) ->
              doc.attach_ace editor
              editor.setValue body
              editor.clearSelection()
              doc.on 'change', (op) ->
                file.update {modified: true}

  Template.editorChrome.events
    'click button#saveButton' : (event) ->
      console.log "clicked save button"
      save Session.get "editorFileId"

  Template.editorChrome.editorFileName = ->
    fileId = Session.get "editorFileId"
    if fileId then Files.findOne(fileId)?.path else "Select file..."

  Template.editor.editorFileId = ->
    Session.get "editorFileId"

  Template.editorChrome.editorFileId = ->
    Session.get "editorFileId"

  Template.editorChrome.buttonSaveClass = ->
    fileId = Session.get "editorFileId"
    file = Files.findOne(fileId) if fileId?
    unless file?.modified then "disabled" else ""
