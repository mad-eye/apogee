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

