Deps.autorun ->
  projectId = Session.get "projectId"
  return unless projectId
  Meteor.subscribe "files", projectId
  Meteor.subscribe "projects", projectId
  Meteor.subscribe "projectStatuses", projectId
  Meteor.subscribe "scriptOutputs", projectId
  Meteor.subscribe "workspaces", projectId
  Meteor.subscribe 'outputs', projectId

Deps.autorun ->
  return if Meteor.loggingIn()
  Meteor.loginAnonymously() unless Meteor.user()

#TODO: Replace this with MadEye.transitoryIssues
@transitoryIssues = null
Meteor.startup ->
  transitoryIssues = new TransitoryIssues

