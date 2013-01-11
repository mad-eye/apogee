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

Meteor.publish "files", (projectId)->
  Files.collection.find
    projectId: projectId

Files.collection.allow(
  #TODO make this more restrictive  
  update: (userId, docs, fields, modifier) -> true
)

Meteor.publish "settings", ->
  settings = Settings.collection.find()

Meteor.publish "projects", (projectId)->
  Projects.collection.find
    _id: projectId

Meteor.methods
  sendNotifyEmail: (emailAddress) ->
    console.log "sendNotifyEmail #{emailAddress}"
    this.unblock()
    Email.send
      to: 'support@madeye.io'
      from: 'support@madeye.io'
      subject: 'NotifyMe'
      text: emailAddress
