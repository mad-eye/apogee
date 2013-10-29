class ProjectStatus extends MadEye.Model

#We should make this collection an in-memory collection only
#But connection: null doesn't work for the client, and it was
#causing errors with the update method.
@ProjectStatuses = new Meteor.Collection 'projectStatus',
  transform: (doc) ->
    new ProjectStatus doc

ProjectStatus.prototype.collection = @ProjectStatuses


