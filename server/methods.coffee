log = new Logger 'projectMethods'

Meteor.publish "projectStatuses", (projectId, sessionId) ->
  if sessionId
    log.debug "Subscribing to projectStatus for id", sessionId
    Meteor.onLogout this, ->
      log.debug "Removing projectStatus for id", sessionId
      ProjectStatuses.remove {sessionId}

  return ProjectStatuses.find {projectId: projectId}, {fields: {heartbeat:0} }

getIcon = (projectId)->
  unavailableIcons = {}
  ProjectStatuses.find({projectId}).forEach (status) ->
    unavailableIcons[status.iconId] = true
  for name, i in USER_ICONS
    continue if unavailableIcons[i]
    return i

projectStatusTimeouts = {}

#This might be obsolete with the onLogout hook above.
#Keep an eye on it, and then remove it if possible.
setProjectStatusTimeout = (sessionId) ->
  Meteor.clearTimeout projectStatusTimeouts[sessionId]
  projectStatusTimeouts[sessionId] = Meteor.setTimeout ->
    log.debug "Removing projectStatus", sessionId
    ProjectStatuses.remove {sessionId}
  , 15*1000
  return

Meteor.methods
  heartbeat: (sessionId, projectId) ->
    setProjectStatusTimeout sessionId

  touchProjectStatus: (sessionId, projectId, fields={})->
    return unless sessionId and projectId
    status = ProjectStatuses.findOne {sessionId, projectId}
    log.trace "touchProjectStatus, session #{sessionId} status exists:", status?
    if status
      status.update fields
    else
      fields = _.extend fields,
        sessionId: sessionId
        projectId: projectId
        iconId: getIcon(projectId)
      #don't give callback, need this to block
      ProjectStatuses.insert fields
    setProjectStatusTimeout sessionId

#TODO: Restrict based on userId
ProjectStatuses.allow
  insert: (userId, doc) -> true
  update: (userId, doc, fields, modifier) -> true
  remove: (userId, doc) -> true

Meteor.startup ->
  #When apogee restarts the timeout doesn't get to clear projectStatuses.
  #Manually remove orphaned projectStatuses.
  ProjectStatuses.remove {}

