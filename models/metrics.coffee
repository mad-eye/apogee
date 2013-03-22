Metrics = new Meteor.Collection("metrics")
 
if Meteor.isClient
  Metrics.add = (metric) ->
    metric.timestamp = new Date()
    metric.projectId = Session.get "projectId"
    metric.level ?= 'debug'
    metric.message = metric.message?[0..200]
    if 'string' == typeof metric.error
      metric.error = metric.error?[0..200]
  Metrics.insert metric
