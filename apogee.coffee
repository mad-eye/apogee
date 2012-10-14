
class File
  constructor: (@name, @isDirectory, @path) ->

getFileTree = ->
  dir1 = new File "dir1", true, []
  file1 = new File "file1", false, ["dir1"]
  file2 = new File "file2", false, []

  return [dir1, file1, file2]

if Meteor.is_client
  FileTree = new Meteor.Collection(null)
  console.log("Found FileTree collection ", FileTree)
  Meteor.startup ->
    files = getFileTree()
    FileTree.insert(file) for file in files

  Template.filetree.files = ->
    return FileTree.find().fetch()

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
          Session.set("user", {username:username})
  )



