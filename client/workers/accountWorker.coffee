#Accounts.ui.config
  #requestPermissions:
    #github: ['user', 'repo']
  #passwordSignupFields: 'USERNAME_AND_EMAIL'

#If no user, log in an anonymous user
Deps.autorun ->
  @name 'login anonymously'
  return if Meteor.loggingIn()
  Meteor.loginAnonymously() unless Meteor.user()


Meteor.startup ->
  Deps.autorun ->
    @name 'subscribe userData'
    Meteor.subscribe 'userData'

  Deps.autorun ->
    @name 'backfill anonyous account names'
    if Meteor.user()?.type == 'anonymous' and !Meteor.user().name
      Meteor.call 'assignName'


