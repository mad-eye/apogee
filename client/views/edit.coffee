# TODO figure out why meteor's stopping coffeescript from doing the usual
# (function(){//code})() thing
# https://github.com/meteor/meteor/pull/85

do ->
  fileTree = new Madeye.FileTree()

  Template.fileTree.files = ->
    fileTree.setFiles Files.find().fetch()
    _.filter fileTree.files, (file)->
      fileTree.isVisible(file)

  Template.fileEntry.fileEntryClass = ->
    clazz = "fileTree-item"
    if @isDir
      clazz += " directory " + if @isOpen() then "open" else "closed"
    else
      clazz += " file"
    clazz += " level" + this.depth
    clazz += " selected" if this.isSelected()
    return clazz

  Template.edit.events
    'click button#saveButton' : (event) ->
      console.log "clicked save button"
      save Session.get "editorFileId"

  Template.fileEntry.events
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
      callback JSON.parse(result.content).body

  getEditorBody = ->
    ace.edit("editor")?.getValue()

  save = (fileId)->
    contents = getEditorBody()
    Meteor.http.call "PUT", fileUrl(fileId), {
      data: {contents: contents}
      headers: {'Content-Type':'application/json'}
    }, (error,result)->
      if error
        console.error(error)
      else
        console.log "save successful"

  Template.editor.rendered = ->
    settings = Settings.findOne()
    editorFileId = Session.get "editorFileId"
    if editorFileId
      editor = ace.edit("editor")
      #TODO: Switch to using sharejs.openExisting
      sharejs.open editorFileId, 'text', "http://#{settings.bolideHost}:#{settings.bolidePort}/channel", (error, doc) ->
        if doc?
          doc.attach_ace editor
        else
          console.log "docless"
          fetchBody editorFileId, (body)->
            sharejs.open editorFileId, 'text', "http://#{settings.bolideHost}:#{settings.bolidePort}/channel", (error, doc) ->
              doc.attach_ace editor
              editor.setValue body
              editor.clearSelection()

  Template.editor.fileName = ->
    fileId = Session.get "editorFileId"
    if fileId then Files.findOne(fileId)?.path else ""
