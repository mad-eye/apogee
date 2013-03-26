
Meteor.publish "projects", (projectId)->
  Projects.collection.find
    _id: projectId

Meteor.publish "files", (projectId)->
  Files.collection.find
    projectId: projectId

findIconId = (projectId)->
  statuses = ProjectStatuses.find {projectId}
  unavailableIcons = {}
  unavailableIcons[status.iconId] = true for status in statuses
  console.log "unavailable icons", unavailableIcons
  for name, i in USER_ICONS
    continue if unavailableIcons[i]
    return i

Meteor.publish "projectStatuses", (projectId, sessionId) ->
  #console.log "Subscribing to projectStatuses with prodId, sesId", projectId, sessionId
  projectStatus = new ProjectStatus({projectId, sessionId})
  projectStatus.iconId = findIconId projectId
  projectStatus.save()
  #console.log "Saved projectStatus", projectStatus
  return ProjectStatuses.collection.find projectId: projectId

Meteor.setInterval ->
  before = Date.now() - 20*1000
  ProjectStatuses.collection.remove({heartbeat: {$lt:before}})
  ProjectStatuses.collection.remove({heartbeat: {$exists:false}})
, 5*1000

#TODO: Restrict based on userId
ProjectStatuses.collection.allow
  insert: (userId, doc) -> true
  update: (userId, doc, fields, modifier) -> true
  remove: (userId, doc) -> true

Files.collection.allow(
  #TODO make this more restrictive  
  #For example, restrict by projectId
  update: (userId, docs, fields, modifier) -> true
  remove: (userId, docs) -> true
)

NewsletterEmails.collection.allow(
  insert: -> true
)

#Used for loading message.
Meteor.methods
  getFileCount: (projectId)->
    return Files.collection.find(projectId: projectId).count()

