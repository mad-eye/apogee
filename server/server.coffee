
Meteor.publish "projects", (projectId)->
  Projects.collection.find
    _id: projectId

Meteor.publish "files", (projectId)->
  Files.collection.find
    projectId: projectId

Files.collection.allow(
  #TODO make this more restrictive  
  #For example, restrict by projectId
  update: (userId, docs, fields, modifier) -> true
  remove: (userId, docs) -> true
)

NewsletterEmails.collection.allow(
  insert: -> true
)

#Used for loading message.
Meteor.methods
  getFileCount: (projectId)->
    return Files.collection.find(projectId: projectId).count()

