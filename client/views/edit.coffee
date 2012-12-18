# TODO Eliminate need to wrap this in do ->
# https://github.com/meteor/meteor/pull/85

do ->
  fileTree = new Madeye.FileTree()

  Template.fileTree.files = ->
    fileTree.setFiles Files.find()
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
        handleError error
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
        console.error(error)
      else
        file.update {modified: false}

  Template.editor.rendered = ->
    Session.set("editorRendered", true)

  Meteor.autorun ->
    return unless Session.equals("editorRendered", true)
    settings = Settings.findOne()
    file = Files.findOne {_id: Session.get "editorFileId"}
    if file
      editor = ace.edit("editor")
      #TODO: Switch to using sharejs.openExisting
      sharejs.open file._id, 'text', "http://#{settings.bolideHost}:#{settings.bolidePort}/channel", (error, doc) ->
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

  # Save file
  Template.editor.events
    'click button#saveButton' : (event) ->
      console.log "clicked save button"
      save Session.get "editorFileId"

  Template.editor.editorFileName = ->
    fileId = Session.get "editorFileId"
    if fileId then Files.findOne(fileId)?.path else "Select file..."

  Template.editor.editorFileId = ->
    Session.get "editorFileId"

  Template.editor.buttonSaveClass = ->
    fileId = Session.get "editorFileId"
    file = Files.findOne(fileId) if fileId?
    unless file?.modified then "disabled" else ""

    
