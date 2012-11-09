require = __meteor_bootstrap__.require
fs = require("fs")

ProcessQueue = new Meteor.Collection(null)

processResult = (result) ->
  result.path = stripSlash result.path
  result.parentPath = stripSlash result.parentPath

  path = result.path
  lastSlashIdx = path.lastIndexOf('/')
  result.name = path.substring(lastSlashIdx+1, path.length)

  parentPathStr = path.substring(0,lastSlashIdx)
  if parentPathStr == ''
    result.parents = []
  else
    result.parents = parentPathStr.split('/')

  result.children = [] if result.isDir

  #Clear out initial _id
  delete result._id
  return result

Meteor.startup(->
  console.log("Starting up server.")
  Files.remove({})
  projectId = "1e694e3c-9e6c-4118-a600-0ce1652c7564"
  dir = "/tmp/bolide/repoClones/#{projectId}"

  walk(dir, dir, (err, results)->
    results ?= []
    results.forEach (result)->
      result.projectId = projectId
      fs.readFile("#{dir}#{result.body}", "utf8", (err, data)->
        result.body = data
        ProcessQueue.insert result
      )
  )

  Meteor.autorun ->
    Fiber(->
      #console.log "Processing queue"
      while ProcessQueue.find().count()
        rawResult = ProcessQueue.findOne()
        ProcessQueue.remove rawResult._id
        #console.log("Processing", rawResult)
        Files.insert processResult(rawResult)
    ).run()
)

