
class File
  constructor: (@name, @isDirectory, @path) ->
    @contents = [] #Directory contents.  To be completed client-side.

  dir_path: -> @path.join "/"
  file_path: ->
    if @path && @path.length
      return this.dir_path() + "/" + @name
    else
      return @name

getFileTree = ->
  files = []
  files.push new File "dir1", true, []
  files.push new File "file1", false, ["dir1"]
  files.push new File "file2", false, []
  files.push new File "dir2", true, []
  files.push new File "dir3", true, ["dir2"]
  files.push new File "file3", true, ["dir2", "dir3"]

  return files

constructFileTree = (files) ->
  files.sort (f1, f2) ->
    if f1.path.length != f2.path.length
      return f1.path.length - f2.path.length
    for i in [0..f1.path.length]
      if f1.path[i] != f2.path[i]
        return f1.path[i] < f2.path[i] ? 1 : -1
    return f1.name < f2.name ? 1 : -1

  fileTree = []
  fileTreeMap = {}
  for file in files
    fileTreeMap[file.file_path()] = file
    console.log("Storing ", file.file_path())
    parent = fileTreeMap[file.dir_path()]
    console.log("Found parent for path " + file.dir_path() + ":", parent)
    if parent
      parent.contents.push(file)
    else
      fileTree.push(file)
    
  return fileTree

if Meteor.is_client
  FileTree = new Meteor.Collection(null)
  console.log("Found FileTree collection ", FileTree)
  Meteor.startup ->
    files = getFileTree()
    FileTree.insert(file) for file in files

  Template.filetree.files = ->
    constructFileTree FileTree.find().fetch()

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



