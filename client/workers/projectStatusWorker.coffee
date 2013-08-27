Meteor.startup ->
  #Create one for the session
  Deps.autorun ->
    @name 'touch projectStatus'
    projectId = Session.get("projectId")
    return unless projectId
    Meteor.call "touchProjectStatus", Session.id, projectId, isHangout: Session.get("isHangout")

  #return a map between file paths and open sharejs session ids
  #Set heartbeat
  Meteor.setInterval ->
    projectId = Session.get "projectId"
    return unless projectId
    Meteor.call "heartbeat", Session.id, projectId
  , 2*1000

  #Set filepath
  Deps.autorun ->
    @name 'set filepath'
    #TODO this seems bolierplatey..
    projectId = Session.get("projectId")
    return unless projectId and MadEye.fileLoader and MadEye.editorState
    projectStatus = ProjectStatuses.findOne {sessionId:Session.id, projectId}
    return unless projectStatus
    projectStatus.update {filePath: MadEye.fileLoader.editorFilePath, connectionId: MadEye.editorState.connectionId}

  #Populate fileTree with ProjectStatuses filePath
  sessionsDep = new Deps.Dependency

  Deps.autorun ->
    @name 'set sessionPaths'
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
    @name 'dirty sessions on changes'
    projectId = Session.get("projectId")
    return unless projectId
    Deps.nonreactive ->
      queryHandle?.stop()

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


