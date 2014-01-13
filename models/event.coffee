class MadEye.Event extends MadEye.Model

@Events = new Meteor.Collection "events", transform: (doc) ->
  new MadEye.Event doc

MadEye.Event.prototype.collection = @Events

recordMixPanel = (name, params)->
  if mixpanel
    mixpanel.track name, params
  else
    console.info "mixPanel is not defined"

@Events.record = (name, params)->
  event = new MadEye.Event(name: name)
  event.timestamp = Date.now()
  _.extend event, params
  Deps.autorun (computation)->
    @name 'save event'
    return unless Meteor.userId()
    event.userId = Meteor.userId()
    event.group = "a" if groupA()
    event.group = "b" if groupB()
    if event.projectId
      project = Projects.findOne event.projectId
      return unless project
      event.isScratch = project.scratch
    event.save()
    #XXX feels a bit hacky..
    recordMixPanel(name, _.extend(params, {userId: event.userId, group: event.group}))
    computation.stop()

