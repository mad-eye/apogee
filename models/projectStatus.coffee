class ProjectStatus extends MadEye.Model

@ProjectStatuses = new Meteor.Collection 'projectStatus',
  transform: (doc) ->
    new ProjectStatus doc

ProjectStatus.prototype.collection = @ProjectStatuses


