# TODO Eliminate need to wrap this in do ->
# https://github.com/meteor/meteor/pull/85

do ->

  fileTree = new Madeye.FileTree()

  projectIsClosed = ->
    Projects.findOne()?.closed

  Template.projectStatus.projectIsClosed = ->
    projectIsClosed()

  Template.projectStatus.projectClosedError = ->
    level: 'error'
    title: 'Project Closed'
    message: 'The project has been closed on the client.'
    uncloseable: true

  #Find how many files the server things, so we know if we have them all.
  Meteor.autosubscribe ->
    Meteor.call 'getFileCount', Session.get('projectId'), (err, count)->
      if err then console.error err; return
      Session.set 'fileCount', count

  Template.projectStatus.projectIsLoading = ->
    return not (Projects.findOne()? || Session.equals 'fileCount', Files.collection.find().count())

  Template.projectStatus.projectLoadingAlert = ->
    level: 'info'
    title: 'Project is Loading'
    message: "...we'll be ready in a moment!"
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
    clazz += " modified" if this.modified
    return clazz

  Template.fileTree.projectName = ->
    Projects.findOne()?.name ? "New project"

  # Select file
  Template.fileTree.events
    'click li.fileTree-item' : (event) ->
      fileId = event.currentTarget.id
      file = fileTree.findById fileId
      file.select()

  Template.editor.preserve("#editor")

  Template.editor.rendered = ->
    Session.set("editorRendered", true)
    resizeEditor()

  editorState = null
  Meteor.startup ->
    editorState = new EditorState "editor"

    Meteor.autorun ->
      console.log "AUTORUN"
      return unless Session.equals("editorRendered", true)
      settings = Settings.findOne()
      return unless settings?
      return if Session.equals "editorFileId", editorState?.file?._id
      file = Files.findOne Session.get "editorFileId"
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
          editorState.fetchBody (body) ->
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
      Session.set "saving", true
      editorState.save (err) ->
        if err
          #Handle error better.
          console.error "Error in save request:", err
        else
          Session.set "saving", false

  Template.editorChrome.editorFileName = ->
    fileId = Session.get "editorFileId"
    if fileId then Files.findOne(fileId)?.path else "Select file..."

  Template.editorChrome.saveButtonMessage = ->
    fileId = Session.get "editorFileId"
    file = Files.findOne(fileId) if fileId?
    unless file?.modified
      "Saved"
    else if projectIsClosed()
      "Offline"
    else if Session.equals "saving", true
      "Saving..."
    else
      "Save Locally"


  Template.editorChrome.showSaveSpinner = ->
    Session.equals "saving", true


  Template.editor.editorFileId = ->
    Session.get "editorFileId"

  Template.editorChrome.editorFileId = ->
    Session.get "editorFileId"

  #FIXME: If a connection is re-established, the file is considered modified==false.
  Template.editorChrome.buttonDisabled = ->
    fileId = Session.get "editorFileId"
    file = Files.findOne(fileId) if fileId?
    if file?.modified and not projectIsClosed() then "" else "disabled"

  resizeEditor = ->
    editorTop = $("#editor").position().top
    editorLeft = $("#editor").position().left
    windowHeight = $(window).height()
    windowWidth = $(window).width()
    newHeight = windowHeight - editorTop - 20
    newWidth = windowWidth - editorLeft - 20
    $("#editor").height(newHeight)
    $("#editor").width(newWidth)
    ace.edit("editor").resize()

  $(window).resize ->
    resizeEditor()


