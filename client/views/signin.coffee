log = new Logger 'signin'

MadEye.loginWithGoogle = ->
  stashWorkspace()
  Meteor.logout()
  Meteor.loginWithGoogle (err) ->
    if err
      log.error "Error in loginWithGoogle:", err
    else
      migrateWorkspace()

MadEye.logout = ->
  stashWorkspace()
  Meteor.logout()
  Meteor.loginAnonymously (err) ->
    if err
      log.error "Error in loginAnonymously:", err
    else
      migrateWorkspace()


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
# with the new workspace.  We do this by stashing the workspace, and then,
# when the new workspace is created, merging
# the old with the new.
###

tempWorkspace = null
stashWorkspace = ->
  log.trace 'Stashing workspace'
  tempWorkspace = getWorkspace()

migrateWorkspace = ->
  workspace = getWorkspace()
  log.trace 'Migrating workspace'
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

