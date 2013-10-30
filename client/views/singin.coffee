Template.googleSigninLink.events
  'click .googleSigninButton': (e) ->
    stashWorkspace()
    Meteor.logout()
    Meteor.loginWithGoogle()

Template.googleSigninButton.events
  'click .googleSigninButton': (e) ->
    stashWorkspace()
    Meteor.logout()
    Meteor.loginWithGoogle()

Template.signin.events
  'click #signoutButton': (e) ->
    stashWorkspace()
    Meteor.logout()
    Meteor.loginAnonymously()

Template.signin.helpers
  isLoggedIn: ->
    Meteor.user() && Meteor.user().type != 'anonymous'

  isLoggedOut: ->
    #We view 'loggedOut' to mean using an anonymous account
    Meteor.user() && Meteor.user().type == 'anonymous'

  hasGoogleLogin: hasGoogleLogin

#Maybe this should go somewhere else?
tempWorkspace = null
stashWorkspace = ->
  tempWorkspace = getWorkspace()

Meteor.startup ->
  Deps.autorun (computation) ->
    return unless getWorkspace() and tempWorkspace
    workspace = getWorkspace()
    for key in _.keys tempWorkspace
      continue if key == '_id' or key == 'userId'
      unless key == 'modeOverrides'
        #set values if there isn't an appropriate key in the workspace.
        workspace[key] = tempWorkspace[key] unless workspace[key]?
      else
        #modeOverrides require treatment by fileId
        workspace.modeOverrides ?= {}
        for fileId, syntaxMode of tempWorkspace.modeOverrides
          unless workspace.modeOverrides[fileId]
            workspace.modeOverrides[fileId] = syntaxMode
    workspace.save()
    tempWorkspace = null

