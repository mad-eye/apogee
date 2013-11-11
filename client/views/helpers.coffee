Meteor.startup ->
  MadEye.startedUp = true

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

Handlebars.registerHelper 'isScratch', isScratch

@projectIsClosed = ->
  getProject()?.closed
  
@fileIsDeleted = ->
  Files.findOne(MadEye.editorState?.fileId)?.deletedInFs

@isTerminal = ->
  project = getProject()
  return false unless project and not project.closed
  return project.tunnels?.terminal?

Handlebars.registerHelper "isTerminal", isTerminal

@isEditorPage = ->
  (Router.template == 'edit') or (Router.tempate == 'editImpressJS')

Handlebars.registerHelper "isHomePage", ->
  return Router.template in ["home", "home2", "getStarted"]

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


