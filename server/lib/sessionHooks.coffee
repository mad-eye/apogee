log = new Logger 'sessionHooks'

loginCallbacks = []
_onLogin = (session) ->
  callback(session) for callback in loginCallbacks

#callback: (session) ->
#TODO: Accept context
Meteor.onLogin = (callback) ->
  unless typeof callback == 'function'
    throw new Error "Meteor.onLogin must be passed a function"
  loginCallbacks.push callback


logoutCallbacks = {}
_onLogout = (sessionId) ->
  callbacks = logoutCallbacks[sessionId]
  return unless callbacks
  callback() for callback in callbacks
  delete logoutCallbacks[sessionId]
  return

#handle is either sessionId, session, or subscription.
#In the end we use any of those to find the sessionId
#callback: () ->
Meteor.onLogout = (handle, callback) ->
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
    throw new Error "Need sessionId for logout callback"
  unless typeof callback == 'function'
    throw new Error "Meteor.onLogout must be passed a sessionId and a function"

  logoutCallbacks[sessionId] ?= []
  logoutCallbacks[sessionId].push callback


existingSessions = []
INTERVAL = Meteor.settings.sessionInterval || 1000
Meteor.setInterval ->
  currentSessions = _.keys Meteor.server.sessions
  newSessions = _.difference currentSessions, existingSessions
  log.debug "newSessions:", newSessions if newSessions.length > 0
  for sessionId in newSessions
    session = Meteor.server.sessions[sessionId]
    _onLogin(session)

  closedSessions = _.difference existingSessions, currentSessions
  log.debug "closedSessions:", closedSessions if closedSessions.length > 0
  for sessionId in closedSessions
    _onLogout(sessionId)

  existingSessions = currentSessions

, INTERVAL
