log = new Logger 'subscriptions'

##
# A reactiveDict of subscription handles.
# To reactively and safely check if
# subscription 'foo' is ready:
# MadEye.subscriptions.get('foo')?.ready()
##
MadEye.subscriptions = new ReactiveDict()

##
# Subscribe, and keep the handle in MadEye.subscriptions.
# Thus we can check for ready() easily.
##
MadEye.subscribe = (name, args...) ->
  log.debug "Subscribing to #{name} with args", args
  handle = Meteor.subscribe.apply this, arguments
  MadEye.subscriptions.set name, handle

Deps.autorun ->
  @name 'subscribe block'
  projectId = Session.get "projectId"
  return unless projectId
  MadEye.subscribe "files", projectId
  MadEye.subscribe "projects", projectId
  MadEye.subscribe "projectStatuses", projectId
  MadEye.subscribe "scriptOutputs", projectId
  MadEye.subscribe "workspaces", projectId
  MadEye.subscribe "activeDirectories", projectId

Deps.autorun ->
  MadEye.subscribe 'customers'
