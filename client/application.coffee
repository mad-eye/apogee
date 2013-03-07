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
    editorState.setLine lineNumber
    'edit'

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

Meteor.startup ->
  transitoryIssues = new TransitoryIssues

