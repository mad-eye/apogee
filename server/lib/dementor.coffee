Future = null
Meteor.startup ->
  Future = Npm.require 'fibers/future'


class Dementor
  constructor: (@projectId) ->

  requestFile: (fileId) ->
    @issueCommand {command: 'request file', fileId}

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



#TODO: Cache by projectId, but find a way to expire cache
@summonDementor = (projectId) -> new Dementor projectId


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

