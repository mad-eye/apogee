log = new Logger 'sessionHooks'

#Example usage:
#Meteor.onConnect (session) ->
#  console.log "Session #{session.id} connected"
#callback: (session) ->
#TODO: Accept context
DDP.onConnect = (callback) ->
  unless typeof callback == 'function'
    throw new Error "Meteor.onConnect must be passed a function"
  connectCallbacks.push callback

#handle is either sessionId, session, or subscription.
#In the end we use any of those to find the sessionId
#callback: () ->
DDP.onDisconnect = (handle, callback) ->
  if typeof handle == 'string'
    sessionId = handle
  #presumably an object
  else if handle._session
    #this is a subscription
    sessionId = handle._session.id
  else if handle.server and handle.socket
    #This is a session
    sessionId = handle.id

  unless sessionId
    throw new Error "Need sessionId for disconnect callback"
  unless typeof callback == 'function'
    throw new Error "Meteor.onDisconnect must be passed a sessionId and a function"

  disconnectCallbacks[sessionId] ?= []
  disconnectCallbacks[sessionId].push callback


connectCallbacks = []
_invokeConnectCallbacks = (session) ->
  callback(session) for callback in connectCallbacks

disconnectCallbacks = {}
_invokeDisconnectCallbacks = (sessionId) ->
  callbacks = disconnectCallbacks[sessionId]
  return unless callbacks
  callback() for callback in callbacks
  delete disconnectCallbacks[sessionId]
  return

existingSessionIds = []
INTERVAL = Meteor.settings.sessionInterval || 1000
Meteor.setInterval ->
  currentSessionIds = _.keys Meteor.server.sessions
  newSessionIds = _.difference currentSessionIds, existingSessionIds
  log.debug "newSessions:", newSessionIds if newSessionIds.length > 0
  for sessionId in newSessionIds
    session = Meteor.server.sessions[sessionId]
    _invokeConnectCallbacks(session)

  closedSessionIds = _.difference existingSessionIds, currentSessionIds
  log.debug "closedSessions:", closedSessionIds if closedSessionIds.length > 0
  for sessionId in closedSessionIds
    _invokeDisconnectCallbacks(sessionId)

  existingSessionIds = currentSessionIds

, INTERVAL
