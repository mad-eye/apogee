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

  markDirty: (collectionName, ids...) ->
    switch collectionName
      when 'projects' then collection = Projects
      when 'files' then collection = Files
    unless collection
      msg = "Tried to markDirty unknown collection: #{collectionName}, #{id}"
      throw Meteor.Error 404, msg
    collection.update {_id: {$in: ids}}, {$set:{}}
