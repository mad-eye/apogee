log = new Logger 'projectStatuses'

Meteor.publish "projectStatuses", (projectId, sessionId) ->
  if sessionId
    log.debug "Subscribing to projectStatus for id", sessionId
    DDP.onDisconnect this, ->
      log.debug "Removing projectStatus for id", sessionId
      ProjectStatuses.remove {sessionId}

  return ProjectStatuses.find {projectId: projectId}, {fields: {heartbeat:0} }

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
      #don't give callback, need this to block
      ProjectStatuses.insert fields
    setProjectStatusTimeout sessionId

#TODO: Restrict based on userId
ProjectStatuses.allow
  insert: (userId, doc) -> true
  update: (userId, doc, fields, modifier) -> true
  remove: (userId, doc) -> true

ProjectStatuses.find().observe
  removed: (doc) ->
    log.trace "Project status removed for project #{doc.projectId}"
    checkHangoutStatus doc.projectId

checkHangoutStatus = (projectId) ->
  project = Projects.findOne projectId
  return unless project?.hangoutUrl
  numHangoutConnections = ProjectStatuses.find({projectId, hangoutUrl:project.hangoutUrl}).count()
  log.trace "Found #{numHangoutConnections} remaining hangout connections for project #{projectId}"
  unless numHangoutConnections
    log.debug "Removing hangout info for project #{projectId}"
    Projects.update projectId, {$unset: {hangoutUrl:true, hangoutId:true}}


Meteor.startup ->
  #When apogee restarts the timeout doesn't get to clear projectStatuses.
  #Manually remove orphaned projectStatuses.
  ProjectStatuses.remove {}

