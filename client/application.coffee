DEFAULT_FILE_NAME = "Select a file"

class Location
  constructor: (@location) ->
    @pathname = @location.pathname.substring(1)
    @pathComponents = @pathname.split("/")
    @params = @makeParameters(@location.search)
    @hash = @location.hash
    

  #TODO: Only handle single values for keys right now.  Fix!
  makeParameters: (query) ->
    params = {}
    for param in [pair.split("=") for pair in query.split("&")]
      key = param[0]
      value = if param.length > 1 then param[1] else true
      params[key] = value
    return params

class Router
  constructor: (@routing) -> #@routing is a (location) -> 'page'
    Meteor.deps.add_reactive_variable(this, 'page', 'home')

  goto: (location) ->
    page = @routing(location)
    console.log("Setting page to", page)
    @page.set(@routing(location))

router = new Router( (location) ->
  console.log("Going to ", location)
  pathname = location.pathname.substring(1)
  if pathname == ''
    return 'home'
  else if pathname == 'edit'
    return 'edit'
  else
    return 'missing'
)

Meteor.startup( ->
  router.goto(document.location)
)

Handlebars.registerHelper('currentPage', ->
  return router?.page()
)

Handlebars.registerHelper('render', (name) ->
  return Template[name]() if Template[name]
)

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
  name = null
  if fileId
    name = Files.findOne(fileId)?.name if fileId
  name ?= DEFAULT_FILE_NAME
  return name

