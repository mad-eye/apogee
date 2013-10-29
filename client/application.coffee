log = new MadEye.Logger 'application'

MadEye.fileLoader = new FileLoader()

Meteor.startup ->
  MadEye.transitoryIssues = new TransitoryIssues
