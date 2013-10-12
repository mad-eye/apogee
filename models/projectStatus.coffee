class ProjectStatus extends MadEye.Model

@ProjectStatuses = new Meteor.Collection 'projectStatus',
  connection: null
  transform: (doc) ->
    new ProjectStatus doc

ProjectStatus.prototype.collection = @ProjectStatuses


