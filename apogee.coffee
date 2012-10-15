Files = new Meteor.Collection("files")

constructFileTree = (files) ->
  files.sort (f1, f2) ->
    return f1.path.length - f2.path.length if f1.path.length != f2.path.length
    for i in [0..f1.path.length]
      return f1.path[i] < f2.path[i] ? 1 : -1 if f1.path[i] != f2.path[i]
    return f1.name < f2.name ? 1 : -1

  fileTree = []
  fileTreeMap = {}
  filePrototype = 
    dir_path: -> @path.join "/"
    file_path: ->
      if @path && @path.length
        return this.dir_path() + "/" + @name
      else
        return @name

  files.forEach (file) ->
    #XXX should probably not have to do this for every file object..
    _.extend(file, filePrototype)
    file.contents ?= []
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


if Meteor.is_server
  require = __meteor_bootstrap__.require
  fs = require("fs")

  processResult = (rawResult) ->
    rawName = rawResult.name
    if rawName.charAt(0) == '/'
      rawName = rawName.substring(1,rawName.length)
    if rawName.charAt(rawName.length) == '/'
      rawName = rawName.substring(0,rawName.length-1)

    lastSlashIdx = rawName.lastIndexOf('/')
    pathStr = rawName.substring(0,lastSlashIdx)
    name = rawName.substring(lastSlashIdx+1, rawName.length)
    path = pathStr.split('/')
    return {name: name, body: rawResult.body, isDir: rawResult.isDir, path: path, projectId: rawResult.projectId}

  Meteor.startup(->
    Files.remove({})
    projectId = "1e694e3c-9e6c-4118-a600-0ce1652c7564"
    dir = "/tmp/bolide/repoClones/#{projectId}"

    console.log("Using dir", dir)
    realResults = []
    needToProcessResults = false
    walk(dir, dir, (err, results)->
      results ?= []
      results.forEach (result)->
        fs.readFile("#{dir}#{result.name}", "utf8", (err, data)->
          selector = {name: result.name, projectId: projectId}
          file = undefined
          realResults.push(
            name: result.name,
            projectId: projectId,
            isDir: result.isDir,
            body: data
          )
          needToProcessResults = true
        )
    )

    #XXX: Need to ditch this kludge for something less embarassing.
    Meteor.setInterval( ->
      if needToProcessResults
        while realResults.length
          result = realResults.pop()
          Files.insert(processResult(result))
        needToProcessResults = false
    , 100)
  )
