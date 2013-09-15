MIN_DEMENTOR_VERSION = '0.1.10'
Future = null
Meteor.startup ->
  Future = Npm.require 'fibers/future'

Meteor.methods
  reportError: (error, projectId) ->
    #TODO: Report this somehow.
    console.error "Error from project #{projectId}:", error

  registerProject: (params) ->
    #TODO: Check for dementor version
    #TODO: Check for node version
    if params.projectId
      project = Projects.findOne params.projectId
    if project
      project.update
        name: params.projectName
        closed: false
        lastOpened: Date.now()
    else
      doc =
        name: params.project
        closed: false
        lastOpened: Date.now()
        created: Date.now()
      doc._id = params.projectId if params.projectId
      project = Project.create doc
    return project._id

  closeProject: (projectId) ->
    Projects.update projectId, closed:true

  addFile: (file) ->
    Files.insert file

  removeFile: (fileId) ->
    console.log "Calling removeFile", fileId
    Files.remove fileId

  updateFile: (fileId, modifier) ->
    console.log "Calling updateFile", fileId, modifier
    Files.update fileId, modifier

Meteor.methods
  requestFile: (projectId, fileId) ->
    console.log "Requesting contents for file #{fileId} and project #{projectId}"
    return commandPending this, {command: 'request file', projectId, fileId},
      (err, result, future) ->
        return future['throw'] err if err
        setShareContents result.fileId, result.contents, (err, response) ->
          return future['throw'] err if err
          console.log "OT ops submitted for version", response.data.v
          future['return'] result

  saveFile: (projectId, fileId, contents) ->
    console.log "Saving contents for file #{fileId} and project #{projectId}"
    return commandPending {command: 'save file', projectId, fileId, contents}

MAX_LENGTH = 16777216 #2^24, a large number of chars

setShareContents = (fileId, contents, callback) ->
  return callback new Error "fileId required for setShareContents" unless fileId
  return callback new Error "Contents cannot be null for file #{fileId}" unless contents
  url = "#{Meteor.settings.public.bolideUrl}/doc/#{fileId}"
  ops = []
  ops.push {d:MAX_LENGTH} #delete operation, clear contents if any
  ops.push contents #insert operation
  options =
    params: {v:0} #goes in query string because of data
    data: ops
    timeout: 10*1000
  Meteor.http.post url, options, callback

#######
# Command infrastructure

Commands = new Meteor.Collection 'commands', connection:null

Meteor.publish 'commands', (projectId) ->
  Commands.find projectId:projectId

Commands.allow
  insert: (userId, doc) -> true
  remove: (userId, doc) -> true

commandFutures = {}
commandCallbacks = {}

#return commandPending normally; it will return a result or throw an exception.
commandPending = (context, commandData, callback) ->
  context.unblock()
  future = new Future()
  commandData.timestamp = Date.now()
  commandId = Commands.insert commandData
  commandFutures[commandId] = future
  commandCallbacks[commandId] = callback
  console.log "End of commandPending"
  return future.wait()
  
Meteor.methods
  commandReceived: (err, result) ->
    console.warn "Error received for command #{result.commandId}:", err if err
    Commands.remove result.commandId
    future = commandFutures[result.commandId]
    delete commandFutures[result.commandId]
    callback = commandCallbacks[result.commandId]
    delete commandCallbacks[result.commandId]
    if callback
      callback err, result, future
    else if future
      if err
        future['throw'] err
      else
        future['return'] result


