Meteor.startup ->
  MadEye.startedUp = true

Handlebars.registerHelper "Settings", ->
  Settings.findOne()

Handlebars.registerHelper "Session", (key) ->
  Session.get key

Handlebars.registerHelper "SessionEquals", (key, value) ->
  Session.equals key, value

Handlebars.registerHelper "hangoutLink", ->
  "#{Meteor.settings.public.hangoutUrl}#{Session.get 'projectId'}"

@getProject = ->
  return null unless MadEye.startedUp
  Projects.findOne(Session.get "projectId")

@isScratch = ->
  project = getProject()
  project?.interview or project?.scratch

Handlebars.registerHelper 'isScratch', ->
  isScratch()

@projectIsClosed = ->
  getProject()?.closed
  
@fileIsDeleted = ->
  Files.findOne(path:MadEye.fileLoader.editorFilePath)?.removed

@isInterview = ->
  getProject()?.interview

Handlebars.registerHelper "isInterview", isInterview

@isTerminal = ->
  tunnels = getProject()?.tunnels
  return false unless tunnels
  return 'terminal' of tunnels

Handlebars.registerHelper "isTerminal", isTerminal

@isEditorPage = ->
  (Meteor.Router.page() == 'edit') or (Meteor.Router.page() == 'editImpressJS')

