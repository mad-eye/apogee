#TODO write tests that all these cases (no settings, one settings, multiple) are handled
Meteor.startup ->
  allSettings = Settings.find()
  if allSettings.length == 0
    setting = _.extend new Setting, Madeye.Settings
    setting.save()
  else if allSettings.length == 1
    setting = _.extend allSettings[0], Madeye.Settings
    setting.save()
  else
    throw "Multiple Entries in Singleton Settings Collection!!"

Meteor.publish "projects", (projectId)->
  Projects.collection.find
    _id: projectId

Meteor.publish "files", (projectId)->
  Files.collection.find
    projectId: projectId

Files.collection.allow(
  #TODO make this more restrictive  
  update: (userId, docs, fields, modifier) -> true
)

NewsletterEmails.collection.allow(
  insert: -> true
)

Meteor.publish "settings", ->
  settings = Settings.collection.find()

