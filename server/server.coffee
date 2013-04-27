
Meteor.publish "projects", (projectId)->
  Projects.find
    _id: projectId

Meteor.publish "files", (projectId)->
  Files.find
    projectId: projectId

Meteor.publish "projectStatuses", (projectId) ->
  ProjectStatuses.find projectId: projectId

Meteor.setInterval ->
  before = Date.now() - 20*1000
  ProjectStatuses.remove({heartbeat: {$lt:before}})
  ProjectStatuses.remove({heartbeat: {$exists:false}})
, 5*1000

#TODO: Restrict based on userId
ProjectStatuses.allow
  insert: (userId, doc) -> true
  update: (userId, doc, fields, modifier) -> true
  remove: (userId, doc) -> true

Files.allow
  #TODO make this more restrictive  
  #For example, restrict by projectId
  update: (userId, docs, fields, modifier) -> true
  remove: (userId, docs) -> true

NewsletterEmails.allow
  insert: -> true

Events.allow
  insert: -> true

Projects.allow
  insert: (userId, doc) -> true

do ->
  getIcon = (projectId)->
    unavailableIcons = {}
    ProjectStatuses.find({projectId}).forEach (status) ->
      unavailableIcons[status.iconId] = true
    for name, i in USER_ICONS
      continue if unavailableIcons[i]
      return i

  Meteor.methods
    #Used for loading message.
    getFileCount: (projectId)->
      return Files.find(projectId: projectId).count()

    updateProjectStatusHearbeat: (sessionId, projectId)->
      status = ProjectStatuses.findOne {sessionId, projectId}
      status.update {heartbeat: Date.now()}

    createProjectStatus: (sessionId, projectId)->
      status = ProjectStatuses.findOne {sessionId, projectId}
      return if status
      ProjectStatuses.insert {sessionId, projectId, iconId: getIcon(projectId), heartbeat: Date.now()}, (err, result)->
        console.error "ERR", err if err
