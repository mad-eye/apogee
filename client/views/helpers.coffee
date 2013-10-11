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
  project = getProject()
  project?.interview or project?.scratch

Handlebars.registerHelper 'isScratch', ->
  isScratch()

@projectIsClosed = ->
  getProject()?.closed
  
@fileIsDeleted = ->
  Files.findOne(MadEye.editorState?.fileId)?.deletedInFs

@isInterview = ->
  getProject()?.interview

Handlebars.registerHelper "isInterview", isInterview

Handlebars.registerHelper "isHomePage", ->
  return Meteor.Router._page in ["home", "home2", "getStarted"]

Handlebars.registerHelper "isHangout", ->
  Session.get "isHangout"

@displayAlert = (alert) ->
  return unless alert?
  html = Template.alert {
    level: alert.level
    title: alert.title
    message: alert.message
  }
  $('#alertBox').append html

@groupA = (testName)->
  return null unless Meteor.userId()
  return MadEye.crc32("#{Meteor.userId()}#{testName}") % 2 == 0

@groupB = (testName)->
  return null unless Meteor.userId()
  return MadEye.crc32("#{Meteor.userId()}#{testName}") % 2 != 0

