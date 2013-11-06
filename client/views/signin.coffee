MadEye.loginWithGoogle = ->
  stashWorkspace()
  Meteor.logout()
  Meteor.loginWithGoogle()

MadEye.logout = ->
  stashWorkspace()
  Meteor.logout()
  Meteor.loginAnonymously()


Template.googleSigninLink.events
  'click .googleSigninButton': (e) ->
    MadEye.loginWithGoogle()

Template.googleSigninButton.events
  'click .googleSigninButton': (e) ->
    MadEye.loginWithGoogle()

Template.signin.events
  'click #signoutButton': (e) ->
    MadEye.logout()

Template.signin.helpers
  isLoggedIn: ->
    Meteor.user() && Meteor.user().type != 'anonymous'

  isLoggedOut: ->
    #We view 'loggedOut' to mean using an anonymous account
    Meteor.user() && Meteor.user().type == 'anonymous'

  hasGoogleLogin: hasGoogleLogin

###
# Stashing workspaces
# 
# When a user logs in or out, we should merge the old workspace preferences
# with the new workspace.  We do this by stashing the workspace, and then
# when the new workspace is created (kicking off the autorun block) merging
# the old with the new.
###

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
