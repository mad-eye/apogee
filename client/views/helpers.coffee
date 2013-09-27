Meteor.startup ->
  MadEye.startedUp = true

Handlebars.registerHelper "Settings", ->
  Settings.findOne()

Handlebars.registerHelper "Session", (key) ->
  Session.get key

Handlebars.registerHelper "SessionEquals", (key, value) ->
  Session.equals key, value

Handlebars.registerHelper "hangoutLink", ->
  "#{MadEye.azkabanUrl}/hangout/#{Session.get 'projectId'}"

@getProject = ->
  return null unless MadEye.startedUp
  Projects.findOne(Session.get "projectId")

@getProjectId = -> Session.get "projectId"

@isScratch = ->
  getProject()?.scratch

Handlebars.registerHelper 'isScratch', ->
  isScratch()

@projectIsClosed = ->
  getProject()?.closed
  
@fileIsDeleted = ->
  Files.findOne(MadEye.editorState.fileId)?.deletedInFs

@isInterview = ->
  getProject()?.interview

Handlebars.registerHelper "isInterview", isInterview

@isTerminal = ->
  getProject()?.tunnels?.terminal?

Handlebars.registerHelper "isTerminal", isTerminal

@isEditorPage = ->
  (Meteor.Router.page() == 'edit') or (Meteor.Router.page() == 'editImpressJS')

