DEFAULT_FILE_NAME = "Select a file"
DEFAULT_PROJECT_NAME = "New Project"


Template.filetree.files = ->
  constructFileTree Files.find().fetch()

Template.filetree.projectName = ->
  return Session.get('projectId') ? DEFAULT_PROJECT_NAME

Template.fileEntry.isSelected = ->
  return Session.equals("currentFileId", this._id)

Template.fileEntry.isOpen = ->
  console.log("Checking isOpen for", this)
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
      sharejs.open(fileId, 'text', 'http://localhost:3003/sjs', (error, doc) ->
        doc.attach_ace(editor)
      )
  )

Template.editor.rendered = ->
  editor = ace.edit("editor")

Template.editor.fileName = ->
  fileId = Session.get("lastTextFileId")
  name = if fileId then Files.findOne(fileId)?.name else null
  name ?= DEFAULT_FILE_NAME
  return name

