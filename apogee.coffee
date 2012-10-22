Files = new Meteor.Collection("files")

constructFileTree = (files) ->
  console.log "Constructing file tree"
  files.sort (f1, f2) ->
    return f1.parents.length - f2.parents.length if f1.parents.length != f2.parents.length
    for i in [0..f1.parents.length]
      return f1.parents[i] < f2.parents[i] ? 1 : -1 if f1.parents[i] != f2.parents[i]
    return f1.name < f2.name ? 1 : -1

  fileTree = []
  fileTreeMap = {}
  filePrototype =
    parent_path: -> @parents.join "/"

  files.forEach (file) ->
    #XXX should probably not have to do this for every file object..
    _.extend(file, filePrototype)
    file.children ?= []
    console.log("Storing file", file.path)
    fileTreeMap[file.path] = file
    parent = fileTreeMap[file.parent_path()]
    console.log("Found parent for path " + file.parent_path() + ":", parent)
    if parent
      parent.children.push(file)
    else
      fileTree.push(file)
    
  return fileTree

if Meteor.is_client

  Template.filetree.files = ->
    constructFileTree Files.find().fetch()

  Template.navbar.account = ->
    return Session.get("user")

  Template.fileEntry.isSelected = ->
    return Session.equals("currentFileId", this._id)

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

  Template.fileEntry.events(
    'click li.file' : (event) ->
      event.preventDefault()
      event.stopPropagation()
      Session.set("currentFileId", event.currentTarget.id)
    )

if Meteor.is_server
  require = __meteor_bootstrap__.require
  fs = require("fs")

  ProcessQueue = new Meteor.Collection(null)

  processResult = (result) ->
    path = result.path
    console.log("Found path " + JSON.stringify(path) )
    if path.charAt(0) == '/'
      path = path.substring(1,path.length)
    if path.charAt(path.length) == '/'
      path = path.substring(0,path.length-1)
    result.path = path

    lastSlashIdx = path.lastIndexOf('/')
    result.name = path.substring(lastSlashIdx+1, path.length)

    parentPathStr = path.substring(0,lastSlashIdx)
    if parentPathStr == ''
      result.parents = []
    else
      result.parents = parentPathStr.split('/')

    #Clear out initial _id
    delete result._id
    return result

  Meteor.startup(->
    Files.remove({})
    projectId = "1e694e3c-9e6c-4118-a600-0ce1652c7564"
    dir = "/tmp/bolide/repoClones/#{projectId}"

    walk(dir, dir, (err, results)->
      results ?= []
      results.forEach (result)->
        fs.readFile("#{dir}#{result.name}", "utf8", (err, data)->
              console.log("adding file", result.name)
              ProcessQueue.insert(processResult(
                 path: result.name,
                 projectId: projectId,
                 isDir: result.isDir,
                 body: data
              ))
        )
    )

    Meteor.autorun ->
      Fiber(->
        console.log "Processing queue"
        while ProcessQueue.find().count()
          rawResult = ProcessQueue.findOne()
          ProcessQueue.remove rawResult._id
          console.log("Processing", rawResult)
          Files.insert processResult(rawResult)
      ).run()
  )
