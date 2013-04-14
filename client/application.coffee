#for urls of the form /edit/PROJECT_ID/PATH_TO_FILE#LINE_NUMBER
#PATH_TO_FILE and LINE_NUMBER are optional
#editRegex = /\/edit\/([-0-9a-f]+)\/?([^#]*)#?([0-9]*)?/
#TODO should probably OR the line and session fields
@editRegex = /\/edit\/([-0-9a-f]+)\/?([^#]*)#?(?:L([0-9]*))?(?:S([0-9a-f-]*))?/
transitoryIssues = null

if Meteor.settings.public.googleAnalyticsId
  _gaq = _gaq || []
  _gaq.push ['_setAccount', Meteor.settings.public.googleAnalyticsId]

do ->
  recordView = ->
    _gaq.push ['_trackPageview'] if _gaq?

  #TODO figure out how to eliminate all the duplicate recordView calls

  Meteor.Router.add editRegex, (projectId, filePath, lineNumber, connectionId)->
    recordView()
    if /hangout=true/.exec(document.location.href.split("?")[1])
      Session.set "isHangout", true
      isHangout = true
    Session.set 'projectId', projectId
    Metrics.add {message:'load', filePath, lineNumber, connectionId, isHangout}
    window.editorState ?= new EditorState "editor"
    editorState.setPath filePath
    editorState.setCursorDestination connectionId
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

Deps.autorun ->
  projectId = Session.get "projectId"
  return unless projectId
  Meteor.subscribe "files", projectId
  Meteor.subscribe "projects", projectId
  Meteor.subscribe "projectStatuses", projectId


Meteor.startup ->
  transitoryIssues = new TransitoryIssues
  projectStatus = ProjectStatuses.findOne {sessionId:Session.get('sessionId')}
  Meteor.call "updateProjectStatusHeartbeat", Session.get("sessionId"), Session.get("projectId")

