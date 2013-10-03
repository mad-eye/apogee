log = new MadEye.Logger 'subscriptions'

MadEye.subscriptions = new ReactiveDict()
Deps.autorun ->
  projectId = Session.get "projectId"
  return unless projectId
  MadEye.subscriptions.set 'files', Meteor.subscribe("files", projectId)
  Meteor.subscribe "projects", projectId
  Meteor.subscribe "projectStatuses", projectId
  Meteor.subscribe "scriptOutputs", projectId
  Meteor.subscribe "workspaces", projectId
  Meteor.subscribe "activeDirectories", projectId
