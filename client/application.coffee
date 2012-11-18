Meteor.Router.add
  '/': ->
    console.log "going home"
    'home'
  '/docs': ->
    console.log("loading docs")
    "edit"
  '/edit/:projectId': (projectId) ->
    Session.set 'projectId', projectId
    console.log 'we are at ', this.canonicalPath
    console.log "our parameters: ", this.params
    console.log "the project id is ", projectId
    'edit'
  '/login': ->
    console.log "logging in"
  '*': ->
    console.log "!!!!!!!!!!"
    "missing"
