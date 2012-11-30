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

  #this is a bit dangerous as it relies on the contents of bolide not changing before
  #this http call reaches it
  #we should figure out how to send a snapshot id or something like that
  save = (fileId)->
    Meteor.http.post fileUrl(fileId), (error,result)->
      if error
        console.error(error)
      else
        console.log "save successful"

  Template.editor.rendered = ->
    editorFileId = Session.get "editorFileId"
    if editorFileId
      editor = ace.edit("editor")
      sharejs.open editorFileId, 'text', "http://localhost:3003/channel", (error, doc) ->
        if doc?
          doc.attach_ace editor
        else
          console.log "docless"
          fetchBody editorFileId, (body)->
            sharejs.open editorFileId, 'text', "http://localhost:3003/channel", (error, doc) ->
              doc.attach_ace editor
              editor.setValue body
              editor.clearSelection()

  Template.editor.fileName = ->
    fileId = Session.get "editorFileId"
    if fileId then Files.findOne(fileId)?.path else ""