class MadEye.Event extends MadEye.Model

@Events = new Meteor.Collection "events", transform: (doc) ->
  new MadEye.Event doc

MadEye.Event.prototype.collection = @Events

recordMixPanel = (name, params)->
  if mixpanel?
    mixpanel.track name, params
  else
    console.info "mixPanel is not defined"

if Meteor.isClient
  @Events.record = (name, params={})->
    event = new MadEye.Event(name: name)
    event.timestamp = Date.now()
    Deps.autorun (computation)->
      @name 'save event'
      return unless Meteor.userId()
      params.userId = Meteor.userId()
      params.group = "a" if groupA()
      params.group = "b" if groupB()
      projectId = Session.get('projectId')
      return unless projectId
      project = Projects.findOne projectId
      return unless project
      params.projectId = projectId
      params.scratch = !!project.scratch
      params.impressJS = !!project.impressJS
      params.standard = !(project.scratch or project.impressJS)
      params.hangout = Session.get 'isHangout'
      _.extend event, params
      event.save()
      recordMixPanel(name, params)
      computation.stop()

