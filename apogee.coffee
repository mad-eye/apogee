
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
    for file in files
      FileTree.insert(file)

  Template.hello.greeting = "Hello apogee!"

  Template.filetree.files = ->
    return FileTree.find().fetch()
