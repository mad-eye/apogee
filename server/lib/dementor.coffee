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
    , 30*1000

  #@returns: {fileId:, contents:, warning:}
  requestFile: (fileId) ->
    @issueCommand {command: 'request file', fileId}

  #@returns: nothing
  saveFile: (fileId, contents) ->
    #XXX: Not waiting for a possible error response.  Should we do that?
    @issueCommand {command: 'save file', fileId, contents}, waitForCallback:false

  #command: {command:, fields...:}
  #options: {waitForCallback:, timeout: (ms)}
  #waitForCallback: default true
  #timeout = 0 means no timeout (wait forever).  default is 15s
  issueCommand: (command, options) ->
    project = Projects.findOne @projectId
    if project.closed
      throw MadEye.Errors.new 'ProjectClosed'
    
    _issueCommand @projectId, command, options

#########
# Dementor access methods
#########

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
  Meteor.clearTimeout dementors[projectId]?.dismissTimeout
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
Future = null
Meteor.startup ->
  Future = Npm.require 'fibers/future'

#Just keep this in-memory.  If we could just do a publish 'add', that'd be better.
Commands = new Meteor.Collection 'commands', connection:null

Meteor.publish 'commands', (projectId) ->
  Commands.find projectId:projectId

Commands.allow
  #insert: (userId, doc) -> true
  remove: (userId, doc) -> true

commandFutures = {}
timeouts = {}

#XXX: returns a future, which must be returned by the calling Meteor.method
_issueCommand = (projectId, command, options={}) ->
  options.waitForCallback ?= true
  command.timestamp = Date.now()
  command.projectId = projectId
  commandId = Commands.insert command
  if options.waitForCallback
    timeout = options.timeout ? 15*1000
    future = new Future()
    commandFutures[commandId] = future
    if timeout
      timeouts[commandId] = Meteor.setTimeout ->
        _resolveCommand commandId, MadEye.Errors.new 'NetworkError'
      , timeout
    return future.wait()

_resolveCommand = (commandId, err, result) ->
  Commands.remove commandId
  future = commandFutures[commandId]
  return unless future
  delete commandFutures[commandId]
  Meteor.clearTimeout timeouts[commandId]
  delete timeouts[commandId]
  if err
    future['throw'] err
  else
    future['return'] result

Meteor.methods
  commandReceived: (err, result) ->
    log.warn "Error received for command #{result.commandId}:", err if err
    _resolveCommand result.commandId, err, result

