Meteor.Router.add
  '/': "home"
  '/docs': -> "docs"
  '/edit/:projectId': (projectId) ->
    Session.set 'projectId', projectId
    'edit'
  '/login': "login"
  '*': "missing"
