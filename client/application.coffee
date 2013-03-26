#for urls of the form /edit/PROJECT_ID/PATH_TO_FILE#LINE_NUMBER
#PATH_TO_FILE and LINE_NUMBER are optional
editRegex = /\/edit\/([-0-9a-f]+)\/?([^#]*)#?([0-9]*)?/
editorState = null
transitoryIssues = null

if Meteor.settings.public.googleAnalyticsId
  _gaq = _gaq || []
  _gaq.push ['_setAccount', Meteor.settings.public.googleAnalyticsId]

do ->
  recordView = ->
    _gaq.push ['_trackPageview'] if _gaq?

  #TODO figure out how to eliminate all the duplicate recordView calls

  Meteor.Router.add editRegex, (projectId, filePath, lineNumber)->
    recordView()
    if /hangout=true/.exec(document.location.href.split("?")[1])
      Session.set "isHangout", true
      isHangout = true
    Session.set 'projectId', projectId
    Metrics.add {message:'load', filePath, lineNumber, isHangout}
    editorState ?= new EditorState "editor"
    editorState.setPath filePath
    "edit"

  Meteor.Router.add
    '/':  ->
      recordView()
      "home"

    '/docs': ->
      recordView()
      "docs"

    '/login': ->

    '/tests': ->
      recordView()
      "tests"

    '/tos': ->
      recordView()
      'tos'

    '/faq': ->
      recordView()
      'faq'

    '/unlinked-hangout': ->
      recordView()
      Session.set "isHangout", true
      'unlinkedHangout'

    '*': ->
      recordView()
      "missing"

Meteor.autosubscribe ->
  Meteor.subscribe "files", Session.get "projectId"
  Meteor.subscribe "projects", Session.get "projectId"
  Meteor.subscribe "projectStatuses", Session.get "projectId"

Meteor.startup ->
  transitoryIssues = new TransitoryIssues
  unless Session.get 'sessionId'
    Session.set "sessionId", Math.floor(Math.random()*100000000) + 1

setFilePath = (filePath) ->
  projectId = Session.get 'projectId'
  sessionId = Session.get 'sessionId'
  return unless projectId? and sessionId?
  projectStatus = ProjectStatuses.findOne {sessionId}
  if projectStatus?
    console.log "Found existing projectStatus", projectStatus
    return if projectStatus.filePath == filePath
    projectStatus.update {filePath:filePath}
  else
    console.log "Found no projectStatus for projectId, sessionId", projectId, sessionId
    projectStatus ?= new ProjectStatus {projectId, sessionId, filePath}
    projectStatus.save()
