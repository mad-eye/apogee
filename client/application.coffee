Template.filetree.files = ->
  constructFileTree Files.find().fetch()

Template.navbar.account = ->
  return Session.get("user")

Template.navbar.events(
  'click #logoutButton' : (event) ->
    event.preventDefault()
    event.stopPropagation()
    Session.set('user', null)
)

Template.signinModal.events(
  'click #signInButton' : (event) ->
    event.preventDefault()
    event.stopPropagation()
    $('#myModal').modal('hide')
    #TODO: Sign in to github.
    paramArray = $('#signInForm').serializeArray()
    username = null
    for field in paramArray
      if (field['name'] == 'username')
        username = field['value']
        break
    if username
      console.log("Found username " + username)
      Session.set("user", username)
)

Template.fileEntry.isSelected = ->
  return Session.equals("currentFileId", this._id)

Template.fileEntry.isOpen = ->
  console.log("Checking isOpen for", this)
  return this.isDir && isDirOpen(this._id)

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
  )


