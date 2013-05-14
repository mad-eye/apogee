Handlebars.registerHelper "Settings", ->
  Settings.findOne()

Handlebars.registerHelper "Session", (key) ->
  Session.get key

Handlebars.registerHelper "SessionEquals", (key, value) ->
  Session.equals key, value

Handlebars.registerHelper "hangoutLink", ->
  "#{Meteor.settings.public.hangoutUrl}#{document.location}"

@isScratch = ->
  project = Projects.findOne(Session.get "projectId")
  project?.interview or project?.scratch

Handlebars.registerHelper 'isScratch', ->
  isScratch()

@projectIsClosed = ->
  Projects.findOne(Session.get 'projectId')?.closed
  
@fileIsDeleted = ->
  Files.findOne(path:MadEye.fileLoader.editorFilePath)?.removed

@isInterview = ->
  Projects.findOne(Session.get "projectId")?.interview

Handlebars.registerHelper "isInterview", isInterview


