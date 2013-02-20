#for urls of the form /edit/PROJECT_ID/PATH_TO_FILE#LINE_NUMBER
#PATH_TO_FILE and LINE_NUMBER are optional
editRegex = /\/edit\/([-0-9a-f]+)\/?([^#]*)#?([0-9]*)?/
editorState = null

Meteor.Router.add editRegex, (projectId, filePath, lineNumber)->
  Session.set 'projectId', projectId.toString()
  editorState ?= new EditorState "editor"
  editorState.setPath filePath
  editorState.setLine lineNumber
  'edit'

Meteor.Router.add
  '/': "home"
  '/docs': -> "docs"
  '/login': "login"
  '/tests': "tests"
  '/tos': 'tos'
  '/faq': 'faq'
  '*': "missing"

Meteor.autosubscribe ->
  Meteor.subscribe "files", Session.get "projectId"
  Meteor.subscribe "projects", Session.get "projectId"
  Meteor.subscribe "settings"

_kmq = _kmq || []

#COPIED FROM https://www.kissmetrics.com/settings
#maybe this could be replaced w/ a single script tag?
Meteor.startup ->
  Meteor.autorun ->
    settings = Settings.findOne()
    return unless settings
    _kmk = settings.kissMetricsId
    _kms = (u)->
      setTimeout ->
        d = document
        f = d.getElementsByTagName('script')[0]
        s = d.createElement('script')
        s.type = 'text/javascript'
        s.async = true
        s.src = u
        f.parentNode.insertBefore(s, f)
      , 1
    _kms('//i.kissmetrics.com/i.js')
    _kms('//doug1izaerwt3.cloudfront.net/' + _kmk + '.1.js')


