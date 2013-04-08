
Meteor.publish "projects", (projectId)->
  Projects.collection.find
    _id: projectId

Meteor.publish "files", (projectId)->
  Files.collection.find
    projectId: projectId

Meteor.publish "projectStatuses", (projectId) ->
  ProjectStatuses.collection.find projectId: projectId

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


do ->
  getIcon = (projectId)->
    statuses = ProjectStatuses.find {projectId}
    unavailableIcons = {}
    unavailableIcons[status.iconId] = true for status in statuses
    for name, i in USER_ICONS
      continue if unavailableIcons[i]
      return i

  Meteor.methods
    #Used for loading message.
    getFileCount: (projectId)->
      return Files.collection.find(projectId: projectId).count()

    createProjectStatus: (sessionId, projectId)->
      status = ProjectStatuses.findOne {sessionId, projectId}
      return if status
      ProjectStatuses.collection.insert {sessionId, projectId, iconId: getIcon(projectId), heartbeat: Date.now()}, (err, result)->
        console.error "ERR", err if err
