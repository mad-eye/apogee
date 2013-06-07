class MadEye.Event extends MadEye.Model

@Events = new Meteor.Collection "events", transform: (doc) ->
  new MadEye.Event doc

MadEye.Event.prototype.collection = @Events

@Events.record = (name, params)->
  event = new MadEye.Event(name: name)
  event.timestamp = Date.now()
  _.extend event, params
  Deps.autorun (computation)->
    return unless Meteor.userId()
    event.userId = Meteor.userId()
    event.group = "a" if groupA()
    event.group = "b" if groupB()
    if event.projectId
      project = Projects.findOne event.projectId
      return unless project
      event.isInterview = project.interview
      event.isScratch = project.scratch
    event.save()
    computation.stop()

