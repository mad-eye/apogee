Future = null
Meteor.startup ->
  Future = Npm.require 'fibers/future'

log = new MadEye.Logger 'dementor'

class Dementor
  constructor: (@projectId) ->
    @_startDismiss()

  heartbeat: ->
    Meteor.clearTimeout @dismissTimeout
    @_startDismiss()

  _startDismiss: ->
    @dismissTimeout = Meteor.setTimeout =>
      log.debug "Dismissing dementor #{@projectId}"
      Meteor.call 'closeProject', @projectId
    , 10*1000

  #@returns: {fileId:, contents:, warning:}
  requestFile: (fileId) ->
    @issueCommand {command: 'request file', fileId}

  #@returns: nothing
  saveFile: (fileId, contents) ->
    @issueCommand {command: 'save file', fileId, contents}, false

  #command: {command:, fields...:}
  issueCommand: (command, waitForCallback=true) ->
    command.timestamp = Date.now()
    command.projectId = @projectId
    commandId = Commands.insert command
    if waitForCallback
      future = new Future()
      commandFutures[commandId] = future
      return future.wait()

#projectId: dementor
dementors = {}

MadEye.touchDementor = (projectId) ->
  dementor = dementors[projectId]
  if dementor
    dementor.heartbeat()
  else
    dementors[projectId] = new Dementor projectId
    Projects.update projectId, {$set: {closed:false}}
  return #if we return dementor, it can't be serialized and things crash.

MadEye.dismissDementor = (projectId) ->
  delete dementors[projectId]
  log.trace "Dismissed dementor #{projectId}"


#TODO: Cache by projectId, but find a way to expire cache
MadEye.summonDementor = (projectId) ->
  dementor = dementors[projectId]
  unless dementor
    Projects.update projectId, {$set: {closed:true}}
    throw MadEye.Errors.new 'ProjectClosed'
  return dementor


#######
# Command infrastructure
#######

#Just keep this in-memory.  If we could just do a publish 'add', that'd be better.
Commands = new Meteor.Collection 'commands', connection:null

Meteor.publish 'commands', (projectId) ->
  Commands.find projectId:projectId

Commands.allow
  #insert: (userId, doc) -> true
  remove: (userId, doc) -> true

commandFutures = {}

Meteor.methods
  commandReceived: (err, result) ->
    console.warn "Error received for command #{result.commandId}:", err if err
    Commands.remove result.commandId
    future = commandFutures[result.commandId]
    return unless future
    delete commandFutures[result.commandId]
    if err
      future['throw'] err
    else
      future['return'] result

