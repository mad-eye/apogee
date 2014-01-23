log = new Logger 'application'

MadEye.fileLoader = new FileLoader()

Meteor.startup ->
  MadEye.transitoryIssues = new TransitoryIssues

  Deps.autorun (computation) ->
    return unless Session.get 'projectId'
    Events.record 'loadProject'
