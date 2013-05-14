Meteor.startup ->
  Meteor.call "updateProjectStatusHeartbeat", Session.get("sessionId"), Session.get("projectId")

  #return a map between file paths and open sharejs session ids
  #Set heartbeat
  Meteor.setInterval ->
    sessionId = Session.get "sessionId"
    projectId = Session.get "projectId"
    return unless sessionId and projectId
    status = ProjectStatuses.findOne {sessionId, projectId}
    Meteor.call "updateProjectStatusHeartbeat", {sessionId, projectId}
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
    projectStatus.update {filePath: MadEye.fileLoader.editorFilePath, connectionId: editorState.connectionId}

  #Populate fileTree with ProjectStatuses filePath
  sessionsDep = new Deps.Dependency

  Deps.autorun ->
    projectId = Session.get "projectId"
    sessionsDep.depend()
    sessionPaths = {}
    Deps.nonreactive ->
      ProjectStatuses.find({projectId}).forEach (status) ->
        sessionPaths[status.sessionId] = status.filePath if status.filePath
    #console.log "Setting sessionPaths from autorun", sessionPaths
    fileTree.setSessionPaths sessionPaths

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

      cursor = ProjectStatuses.find {projectId}
      queryHandle = cursor.observeChanges
        added: (id, fields)->
          #console.log "ADDED", id, fields
          sessionsDep.changed()

        changed: (id, fields)->
          #console.log "CHANGED", id, fields if fields.filePath?
          sessionsDep.changed() if fields.filePath?

        removed: (id, fields)->
          # console.log "REMOVED", id, fields
          sessionsDep.changed()


