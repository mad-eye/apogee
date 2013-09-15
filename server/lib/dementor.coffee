Future = null
Meteor.startup ->
  Future = Npm.require 'fibers/future'


class Dementor
  constructor: (@projectId) ->

  requestFile: (fileId) ->
    @issueCommand {command: 'request file', fileId}

  #command: {command:, fields...:}
  issueCommand: (command) ->
    future = new Future()
    command.timestamp = Date.now()
    command.projectId = @projectId
    commandId = Commands.insert command
    commandFutures[commandId] = future
    return future.wait()



#TODO: Cache by projectId, but find a way to expire cache
@summonDementor = (projectId) -> new Dementor projectId


#######
# Command infrastructure
#######

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

