#Accounts.ui.config
  #requestPermissions:
    #github: ['user', 'repo']
  #passwordSignupFields: 'USERNAME_AND_EMAIL'

#If no user, log in an anonymous user
Deps.autorun ->
  return if Meteor.loggingIn()
  Meteor.loginAnonymously() unless Meteor.user()

Template.signin.helpers
  isLoggedIn: ->
    Meteor.user()?.type != 'anonymous'

  isLoggedOut: ->
    #We view 'loggedOut' to mean using an anonymous account
    Meteor.user() && Meteor.user().type == 'anonymous'


Template.signin.events
  'click #signinButton': (e) ->
    console.log "Clicked signinButton"
    Meteor.logout()
    Meteor.loginWithGoogle()

  'click #signoutButton': (e) ->
    console.log "Clicked signoutButton"
    Meteor.logout()

Meteor.startup ->
  Deps.autorun ->
    Meteor.subscribe 'userData'
