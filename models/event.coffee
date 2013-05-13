class MadEye.Event extends MadEye.Model
  constructor: (data) ->
    super data

@Events = new Meteor.Collection "events", transform: (doc) ->
  new MadEye.Event doc

@Events.record = (name, params)->
  event = new MadEye.Event(name: name)
  event.timestamp = Date.now()
  _.extend event, params
  Deps.autorun (computation)->
    if event.projectId
      project = Projects.findOne event.projectId
      return unless project
      _.extend event, {isInterview: project.interview}
    return unless Meteor.userId()
    _.extend event, {userId: Meteor.userId()}
    event.save()
    computation.stop()

MadEye.Event.prototype.collection = @Events