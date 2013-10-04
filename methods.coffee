Meteor.methods
  addActiveDirectory: (projectId, path)->
    unless ActiveDirectories.findOne({path: path, projectId: projectId})
      ActiveDirectories.insert {_id: "#{projectId}__#{path}", path: path, activated: Date.now(), projectId: projectId}
