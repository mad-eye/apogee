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
    stashWorkspace()
    Meteor.logout()
    Meteor.loginWithGoogle (err) ->
      Workspaces.insert userId: Meteor.userId() unless getWorkspace()

  'click #signoutButton': (e) ->
    stashWorkspace()
    Meteor.logout()
    Meteor.loginAnonymously ->
      Workspaces.insert userId: Meteor.userId() unless getWorkspace()

Meteor.startup ->
  Deps.autorun ->
    Meteor.subscribe 'userData'


#Maybe this should go somewhere else?
tempWorkspace = null
stashWorkspace = ->
  tempWorkspace = getWorkspace()
  console.log "Stashing workspace", tempWorkspace

Meteor.startup ->
  Deps.autorun (computation) ->
    return unless getWorkspace() and tempWorkspace
    workspace = getWorkspace()
    for key in _.keys tempWorkspace
      continue if key == '_id' or key == 'userId'
      #set values if there isn't an appropriate key in the workspace.
      workspace[key] = tempWorkspace[key] unless workspace[key]?
    console.log "Saving workspace", workspace
    workspace.save()
    tempWorkspace = null

