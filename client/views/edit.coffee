# TODO either figure out why meteor's stopping coffeescript from doing the usual
# (function(){//code})() thing or be more careful letting everything leak into the global
# namespace
# https://github.com/meteor/meteor/pull/85


DEFAULT_FILE_NAME = "Select a file"
DEFAULT_FILE_BODY = "Empty File"
ROOT_DIR_NAME = "the root directory."

#TODO replace variable names w/
#methods for getting/setting
#selectedFileId
#displayedFileId
#method for currentDirectory

editor = null

fileAndId = (file) ->
  return [null, null] unless file?
  if typeof(file) == 'object'
    fileId = file._id
  else if typeof(file) == 'string'
    fileId = file
    file = Files.findOne(fileId)
  else
    console.error "Called setFileId with incorrect argument", file
    #console.log "typeof:", typeof(file)
    return
  return [file, fileId]

openParents = (file) ->
  [file, fileId] = fileAndId file
  if file.parents.length
    parent = Files.findOne({path:file.parent_path()})
    if parent
      openDir(parent._id)
      openParents(parent)

setFileId = (file) ->
  [file, fileId] = fileAndId file
  Session.set("currentFileId", fileId)
  if !file.isDir
    Session.set("lastTextFileId", fileId)

Template.fileTree.files = ->
  fileTree = new Madeye.FileTree(Files.find().fetch())
  return fileTree.files

Template.fileEntry.isSelected = ->
  return Session.equals("currentFileId", this._id)

Template.fileEntry.isOpen = ->
  #console.log("Checking isOpen for", this)
  return this.isDir && isDirOpen(this._id)

Template.fileEntry.fileEntryClass = ->
  clazz = "fileTree-item"
  if this.isDir
    clazz += " directory " + if isDirOpen(this._id) then "open" else "closed"
  else
    clazz += " file"
#  if this.parents.length
#    clazz += " level" + this.parents.length
  clazz += " selected" if Session.equals("currentFileId", this._id)
  return clazz


Template.fileEntry.events(
  'click li.fileTree-item' : (event) ->
    console.log "Got click event", event
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()
    fileId = event.currentTarget.id
    file = Files.findOne(_id:fileId)
    setFileId(file)
    if file.isDir
      toggleDir fileId
    else
      #console.log "Setting lastTextFileId to " + fileId
      Session.set("lastTextFileId", fileId)
  )

Template.editor.rendered = ->
  [currentFile, currentFileId] = fileAndId Session.get("lastTextFileId")
  if currentFileId
    editor = ace.edit("editor")
    sharejs.open currentFileId, 'text', "http://localhost:3003/channel", (error, doc) ->
      doc.attach_ace editor

Template.editor.fileName = ->
  fileId = Session.get "lastTextFileId"
  name = if fileId then Files.findOne(fileId)?.name else null
  name ?= DEFAULT_FILE_NAME
  return name
