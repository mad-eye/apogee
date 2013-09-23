getIcon = (projectId)->
  unavailableIcons = {}
  ProjectStatuses.find({projectId}).forEach (status) ->
    unavailableIcons[status.iconId] = true
  for name, i in USER_ICONS
    continue if unavailableIcons[i]
    return i

Meteor.methods
  heartbeat: (sessionId, projectId) ->
    ProjectStatuses.update {sessionId, projectId}, {$set: {heartbeat: Date.now()}}

  touchProjectStatus: (sessionId, projectId, fields={})->
    return unless sessionId and projectId
    status = ProjectStatuses.findOne {sessionId, projectId}
    fields.heartbeat = Date.now()
    if status
      status.update fields
    else
      fields = _.extend fields,
        sessionId: sessionId
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
