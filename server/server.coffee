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
  console.log("Starting up server.")
  Files.remove({})
  projectId = "1e694e3c-9e6c-4118-a600-0ce1652c7564"
  dir = "/tmp/bolide/repoClones/#{projectId}"

  walk(dir, dir, (err, results)->
    results ?= []
    results.forEach (result)->
      fs.readFile("#{dir}#{result.name}", "utf8", (err, data)->
            #console.log("adding file", result.name)
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
      #console.log "Processing queue"
      while ProcessQueue.find().count()
        rawResult = ProcessQueue.findOne()
        ProcessQueue.remove rawResult._id
        #console.log("Processing", rawResult)
        Files.insert processResult(rawResult)
    ).run()
)

