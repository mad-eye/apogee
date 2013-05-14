class MadEye.Workspace extends MadEye.Model
  constructor: (data) ->
    super data

@Workspaces  = new Meteor.Collection "workspaces", transform: (doc) ->
  new MadEye.Workspace doc

MadEye.Workspace.prototype.collection = @Workspaces

