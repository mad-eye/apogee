class ProjectStatus extends MadEye.Model

options =
  transform: (doc) ->
    new ProjectStatus doc

if Meteor.isServer
  options.connection = null

@ProjectStatuses = new Meteor.Collection 'projectStatus', options

ProjectStatus.prototype.collection = @ProjectStatuses


