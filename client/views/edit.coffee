DEFAULT_FILE_NAME = "Select a file"
DEFAULT_PROJECT_NAME = "New Project"
ROOT_DIR_NAME = "the root directory."


Template.filetree.files = ->
  constructFileTree Files.find().fetch()

Template.filetree.projectName = ->
  return Session.get('projectId') ? DEFAULT_PROJECT_NAME

Template.fileEntry.isSelected = ->
  return Session.equals("currentFileId", this._id)

Template.fileEntry.isOpen = ->
  #console.log("Checking isOpen for", this)
  return this.isDir && isDirOpen(this._id)

Template.fileEntry.fileEntryClass = ->
  clazz = "filetree-item"
  if this.isDir
    clazz += " directory " + if isDirOpen(this._id) then "open" else "closed"
  else
    clazz += " file"
  if this.parents.length
    clazz += " level" + this.parents.length
  clazz += " selected" if Session.equals("currentFileId", this._id)
  return clazz


Template.fileEntry.events(
  'click li.filetree-item' : (event) ->
    console.log "Got click event", event
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()
    fileId = event.currentTarget.id
    Session.set("currentFileId", fileId)
    file = Files.findOne(_id:fileId)
    if file.isDir
      toggleDir fileId
    else
      Session.set("lastTextFileId", fileId)
)

Template.editor.fileName = ->
  fileId = Session.get("lastTextFileId")
  name = if fileId then Files.findOne(fileId)?.name else null
  name ?= DEFAULT_FILE_NAME
  return name

Template.editor.rendered = ->
  iFrame = $("#editor_iframe")[0]
  iFrame.src = "http://localhost:3003/editor.html?id=" + Session.get("currentFileId")

Template.filetree.rendered = ->
  $("#addButton").tooltip()
  $("#deleteButton").tooltip()

Template.filetree.currentFileName = ->
  fileId = Session.get("currentFileId")
  name = if fileId then Files.findOne(fileId)?.name else null
  name ?= "selected file."
  return name

Template.filetree.currentDirName = ->
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
