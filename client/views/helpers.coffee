Meteor.startup ->
  MadEye.startedUp = true

Handlebars.registerHelper "Session", (key) ->
  Session.get key

Handlebars.registerHelper "SessionEquals", (key, value) ->
  Session.equals key, value

Handlebars.registerHelper 'editorState', ->
  MadEye.editorState

Handlebars.registerHelper "hangoutLink", ->
  "#{MadEye.azkabanUrl}/hangout/#{Session.get 'projectId'}"

Handlebars.registerHelper 'showTopnav', ->
  return false if Session.get "isHangout"
  return false if Session.get 'zen'
  return true

@getProject = ->
  return null unless MadEye.startedUp
  Projects.findOne(Session.get "projectId")

@getProjectId = -> Session.get "projectId"

@projectIsClosed = ->
  getProject()?.closed
  
## Terminal helpers
@isTerminalEnabled = ->
  return false if Session.get 'fileOnly'
  project = getProject()
  return false unless project and not project.closed
  terminal = project.tunnels?.terminal
  if terminal?
    if terminal.type == "readOnly"
      return true
    else if terminal.type == "readWrite"
      return Meteor.settings.public.fullTerminal
  return

Handlebars.registerHelper "isTerminalEnabled", isTerminalEnabled

@isReadOnlyTerminal = ->
  return getProject()?.tunnels.terminal.type == "readOnly"

Handlebars.registerHelper "isReadOnlyTerminal", isReadOnlyTerminal

@isTerminalOpened = ->
  return false unless isTerminalEnabled()
  return MadEye.terminal?.opened
  

## Page/project Info
@isEditorPage = ->
  (Router.template == 'edit') or
    (Router.template == 'wholeEditor') or
    (Router.template == 'editImpressJS')

Handlebars.registerHelper "isHangout", ->
  Session.get "isHangout"

@isScratch = ->
  getProject()?.scratch

Handlebars.registerHelper 'isScratch', isScratch

## Alerts
@displayAlert = (alert) ->
  return unless alert?
  html = Template.alert {
    level: alert.level
    title: alert.title
    message: alert.message
  }
  $('#alertBox').append html

@fileIsDeleted = ->
  Files.findOne(MadEye.editorState?.fileId)?.deletedInFs

## AB Testing

@groupA = (testName)->
  return null unless Meteor.userId()
  return MadEye.crc32("#{Meteor.userId()}#{testName}") % 2 == 0

@groupB = (testName)->
  return null unless Meteor.userId()
  return MadEye.crc32("#{Meteor.userId()}#{testName}") % 2 != 0

## CDN

#Static prefix for static assets, like videos and ace js files
Handlebars.registerHelper 'staticPrefix', ->
  Meteor.settings.public.staticPrefix ? ''
