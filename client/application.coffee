Meteor.Router.add
  '': ->
    console.log "going home"
    'home'
  'yo': ->
    console.log("??????")
    "edit"
  '/edit/:projectId': (projectId) ->
    console.log("??????")
    Session.set 'projectId', projectId
    console.log 'we are at ' + this.canonicalPath;
    console.log "our parameters: " + this.params;
    'edit'
  '*': ->
    console.log "!!!!!!!!!!"
    "missing"
