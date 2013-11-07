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


#Maybe this should go somewhere else?
tempWorkspace = null
stashWorkspace = ->
  tempWorkspace = getWorkspace()

Meteor.startup ->
  Deps.autorun (computation) ->
    @name 'migrate workspace'
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
