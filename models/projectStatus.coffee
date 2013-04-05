class ProjectStatus
  constructor: (rawJSON) ->
    _.extend(@, rawJSON)

ProjectStatuses = new Meteor.Model("projectStatus", ProjectStatus)

#return a map between file paths and open sharejs session ids
if Meteor.isClient
  do ->
    sessionsDep = new Deps.Dependency
    ProjectStatuses.getSessions = (filePath) ->
      projectId = Session.get "projectId"
      Deps.depend sessionsDep
      results = []
      Deps.nonreactive ->
        statuses = ProjectStatuses.find {projectId}
        for status in statuses
          continue unless status.filepath
          f = Files.findOne {path: status.filepath}
          if filePath == f.visibleParent().path
            results.push status
      return results

    #Set heartbeat
    Meteor.setInterval ->
      sessionId = Session.get "sessionId"
      projectId = Session.get "projectId"
      return unless sessionId and projectId
      status = ProjectStatuses.findOne {sessionId, projectId}
      status?.update {heartbeat: Date.now()}
    , 2*1000

    #Set filepath
    Deps.autorun ->
      #TODO this seems bolierplatey..
      sessionId = Session.get("sessionId")
      projectId = Session.get("projectId")
      return unless Session.equals("editorRendered", true) and sessionId and projectId
      projectStatus = ProjectStatuses.findOne {sessionId, projectId}
      return unless projectStatus
      projectStatus.update {filepath: editorState.getPath(), connectionId: editorState.getConnectionId()}

    #Invalidate sessionsDep on important changes
    queryHandle = null
    Deps.autorun (computation)->
      projectId = Session.get("projectId")
      return unless projectId
      Deps.nonreactive ->
        queryHandle?.stop()
        unless Session.get("sessionId")?
          Session.set "sessionId", Meteor.uuid()
        sessionId = Session.get "sessionId"
        Meteor.call "createProjectStatus", sessionId, projectId

        cursor = ProjectStatuses.collection.find {projectId}
        queryHandle = cursor.observeChanges
          added: (id, fields)->
            console.log "ADDED", id, fields
            sessionsDep.changed()

          changed: (id, fields)->
            console.log "CHANGED", id, fields if fields.filepath?
            sessionsDep.changed() if fields.filepath?

          removed: (id, fields)->
            console.log "REMOVED", id, fields
            sessionsDep.changed()

