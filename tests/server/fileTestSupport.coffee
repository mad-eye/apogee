Meteor.startup ->
  Files.allow
    insert: (userId, doc) -> true


Meteor.methods
  makeProject: (projectId, projectName) ->
    doc = name:projectName, lastOpened: Date.now(), created: Date.now()
    doc._id = projectId if projectId
    projectId = Projects.insert doc
    return projectId

  findProject: (projectId) ->
    return Projects.findOne projectId
