
Meteor.publish "projects", (projectId)->
  Projects.find
    _id: projectId

Meteor.publish "files", (projectId)->
  Files.find
    projectId: projectId

Meteor.publish "scriptOutputs", (projectId) ->
  ScriptOutputs.find projectId: projectId

Meteor.publish "workspaces", (projectId) ->
  #Create workspaces for old accounts that don't have any.
  unless Workspaces.findOne(userId: @userId)
    Workspaces.insert userId: @userId

  Workspaces.find userId: @userId

Meteor.publish "activeDirectories", (projectId)->
  ActiveDirectories.find projectId: projectId

Files.allow
  #TODO make this more restrictive  
  #For example, restrict by projectId
  insert: (userId, doc) -> true
  update: (userId, docs, fields, modifier) -> true
  remove: (userId, docs) -> true

NewsletterEmails.allow
  insert: -> true

Events.allow
  insert: -> true

Projects.allow
  insert: (userId, doc) -> true
  update: (userId, doc) -> true

ScriptOutputs.allow
  insert: -> true

Workspaces.allow
  insert: -> true
  update: -> true

ActiveDirectories.allow
  insert: -> true
  update: -> true

