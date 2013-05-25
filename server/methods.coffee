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

  heartbeat: (userId, projectId) ->
    ProjectStatuses.update {userId, projectId}, {$set: {heartbeat: Date.now()}}

  touchProjectStatus: (userId, projectId)->
    return unless userId and projectId
    status = ProjectStatuses.findOne {userId, projectId}
    if status
      status.update {heartbeat: Date.now()}
    else
      ProjectStatuses.insert {userId, projectId, iconId: getIcon(projectId), heartbeat: Date.now()}, (err, result)->
        console.error "ERR", err if err

  markDirty: (collectionName, ids...) ->
    switch collectionName
      when 'projects' then collection = Projects
      when 'files' then collection = Files
    unless collection
      msg = "Tried to markDirty unknown collection: #{collectionName}, #{id}"
      throw Meteor.Error 404, msg
    collection.update {_id: {$in: ids}}, {$set:{}}
