#Accounts.ui.config
  #requestPermissions:
    #github: ['user', 'repo']
  #passwordSignupFields: 'USERNAME_AND_EMAIL'

#If no user, log in an anonymous user
Deps.autorun ->
  return if Meteor.loggingIn()
  Meteor.loginAnonymously() unless Meteor.user()


Meteor.startup ->
  Deps.autorun ->
    Meteor.subscribe 'userData'


