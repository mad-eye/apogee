#TODO remove insecure package and setup rules for each collection
# Files.allow(
#   insert: (userId, doc) -> true
#   update: (userId, docs, fields, modifier) -> true
#   remove: (userId, docs) -> true
# )

#TODO write tests that all these cases (no settings, one settings, multiple) are handled
Meteor.startup ->
  allSettings = Settings.find().fetch()
  if allSettings.length == 0
    Settings.insert Madeye.Settings
  else if allSettings.length == 1
    Settings.update allSettings[0]._id, Madeye.Settings
  else
    throw "Multiple Entries in Singleton Settings Collection!!"

Meteor.publish "files", (projectId)->
  Files.collection.find
    projectId: projectId

Files.collection.allow(
 #insert: (userId, doc) -> true
 update: (userId, docs, fields, modifier) -> true
 #remove: (userId, docs) -> true
)

Meteor.publish "settings", ->
  settings = Settings.find()

Meteor.publish "projects", (projectId)->
  Projects.find
    _id: projectId
