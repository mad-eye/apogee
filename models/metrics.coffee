Metrics = new Meteor.Collection("metrics")
 
if Meteor.isClient
  Metrics.add = (metric) ->
    metric.timestamp = new Date()
    metric.projectId = Session.get "projectId"
    metric.level ?= 'debug'
    Metrics.insert metric
  
