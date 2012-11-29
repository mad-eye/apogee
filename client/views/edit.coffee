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

  Template.fileEntry.events
    'click li.fileTree-item' : (event) ->
      fileId = event.currentTarget.id
      file = fileTree.findById fileId
      file.select()

  fetchBody = (fileId, callback) ->
    settings = Settings.findOne()
    url = "http://#{settings.httpHost}:#{settings.httpPort}"
    url = "#{url}/project/#{Projects.findOne()._id}/file/#{fileId}"
    Meteor.http.get url, (error,result)->
      console.log result, result.content.body
      callback JSON.parse(result.content).body

  Template.editor.rendered = ->
    editorFileId = Session.get "editorFileId"
    if editorFileId
      editor = ace.edit("editor")
      sharejs.open editorFileId, 'text', "http://localhost:3003/channel", (error, doc) ->
        if doc?
          doc.attach_ace editor
        else
          fetchBody editorFileId, (body)->
            sharejs.open editorFileId, 'text', "http://localhost:3003/channel", (error, doc) ->
              doc.attach_ace editor
              editor.setValue body
              editor.clearSelection()

  Template.editor.fileName = ->
    fileId = Session.get "editorFileId"
    if fileId then Files.findOne(fileId)?.path else ""