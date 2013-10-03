Meteor.methods
  addActiveDirectory: (projectId, path)->
    unless ActiveDirectories.findOne({path: path})
      ActiveDirectories.insert {_id: "#{projectId}__#{path}", path: path, activated: Date.now(), projectId: projectId}
