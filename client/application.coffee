Meteor.Router.add
  '/': "home"
  '/docs': -> "docs"
  '/edit/:projectId': (projectId) ->
    Session.set 'projectId', projectId.toString()
    'edit'
  '/login': "login"
  '*': "missing"

Meteor.autosubscribe ->
  Meteor.subscribe "files", Session.get "projectId"

Meteor.autosubscribe ->
  Meteor.subscribe "projects", Session.get "projectId"

Meteor.subscribe "settings"
