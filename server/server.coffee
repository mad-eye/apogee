#only allow modification of a files' contents?
Files.allow(
  insert: (userId, doc) -> true
  update: (userId, docs, fields, modifier) -> true
  remove: (userId, docs) -> true
)

Meteor.publish "files", (projectId)->
  Files.find
    projectId: projectId
