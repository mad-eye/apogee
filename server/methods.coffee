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

  touchProjectStatus: (userId, projectId, fields={})->
    return unless userId and projectId
    status = ProjectStatuses.findOne {userId, projectId}
    fields.heartbeat = Date.now()
    if status
      status.update fields
    else
      fields = _.extend fields,
        userId: userId
        projectId: projectId
        iconId: getIcon(projectId)
      ProjectStatuses.insert fields, (err, result)->
        console.error "ERR", err if err

  markDirty: (collectionName, ids...) ->
    switch collectionName
      when 'projects' then collection = Projects
      when 'files' then collection = Files
    unless collection
      msg = "Tried to markDirty unknown collection: #{collectionName}, #{id}"
      throw Meteor.Error 404, msg
    collection.update {_id: {$in: ids}}, {$set:{}}
