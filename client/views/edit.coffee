DEFAULT_FILE_NAME = "Select a file"
DEFAULT_PROJECT_NAME = "New Project"
ROOT_DIR_NAME = "the root directory."


DEFAULT_FILE_NAME = "Select a file"
DEFAULT_FILE_BODY = "Empty File"
DEFAULT_PROJECT_NAME = "New Project"
ROOT_DIR_NAME = "the root directory."

fileAndId = (file) ->
  if typeof(file) == 'object'
    console.log "Found object."
    fileId = file._id
  else if typeof(file) == 'string'
    console.log "Found string."
    fileId = file
    file = Files.findOne(fileId)
  else
    console.error "Called setFileId with incorrect argument", file
    console.log "typeof:", typeof(file)
    return
  completeFile(file)
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

Template.fileTree.rendered = ->
  $("#addButton").tooltip()
  $("#deleteButton").tooltip()

Template.fileTree.files = ->
  constructFileTree Files.find().fetch()

Template.fileTree.currentFileName = ->
  fileId = Session.get("currentFileId")
  name = if fileId then Files.findOne(fileId)?.name else null
  name ?= "selected file."
  return name

Template.fileTree.projectName = ->
  return Session.get('projectId') ? DEFAULT_PROJECT_NAME

Template.fileTree.currentDirName = ->
  fileId = Session.get("currentFileId")
  file = if fileId then Files.findOne(fileId) else null
  name = null
  if file?
    if file.isDir
      name = file.name
    else if file.parents.length
      name = file.parents[file.parents.length-1]
  name ?= ROOT_DIR_NAME
  return name


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
  if this.parents.length
    clazz += " level" + this.parents.length
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
      Session.set("lastTextFileId", fileId)
  )

Template.editor.rendered = ->
  editor = ace.edit("editor")
  currentFileId = Session.get("currentFileId")
  if currentFileId
    sharejs.open(currentFileId, 'text', "http://localhost:3003/channel", (error, doc) ->
      doc.attach_ace(editor)
    )

Template.editor.fileBody = ->
  fileId = Session.get("lastTextFileId")
  body = if fileId then Files.findOne(fileId)?.body else null
  return body

Template.editor.fileName = ->
  fileId = Session.get("lastTextFileId")
  name = if fileId then Files.findOne(fileId)?.name else null
  name ?= DEFAULT_FILE_NAME
  return name

Template.addFileModal.dirList = ->
  file for file in constructFileTree(Files.find().fetch()) when file.isDir

Template.signinModal.events(
  'click #addFileSubmit' : (event) ->
    event.preventDefault()
    event.stopPropagation()
    $('#addFileModal').modal('hide')
    #TODO: Sign in to github.
    #paramArray = $('#signInForm').serializeArray()
    #username = null
    #for field in paramArray
      #if (field['name'] == 'username')
        #username = field['value']
        #break
    #if username
      #console.log("Found username " + username)
      #Session.set("user", username)
)
