Meteor.startup ->
  #Create one for the session
  Deps.autorun ->
    userId = Meteor.userId()
    projectId = Session.get("projectId")
    return unless userId and projectId
    Meteor.call "touchProjectStatus", userId, projectId, isHangout: Session.get("isHangout")

  #return a map between file paths and open sharejs session ids
  #Set heartbeat
  Meteor.setInterval ->
    userId = Meteor.userId()
    projectId = Session.get "projectId"
    return unless userId and projectId
    Meteor.call "heartbeat", userId, projectId
  , 2*1000

  #Set filepath
  Deps.autorun ->
    #TODO this seems bolierplatey..
    userId = Meteor.userId()
    projectId = Session.get("projectId")
    return unless Session.equals("editorRendered", true) and userId and projectId
    projectStatus = ProjectStatuses.findOne {userId, projectId}
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
        sessionPaths[status.userId] = status.filePath if status.filePath
    #console.log "Setting sessionPaths from autorun", sessionPaths
    fileTree.setSessionPaths sessionPaths

  #Invalidate sessionsDep on important changes
  queryHandle = null
  Deps.autorun (computation)->
    projectId = Session.get("projectId")
    return unless projectId and Meteor.userId()
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


