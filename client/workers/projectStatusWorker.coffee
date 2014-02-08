log = new Logger 'projectStatusWorker'

Meteor.startup ->
  #Clear out any vestigial following (the connectionId will be wrong anyway)
  unfollowUser()

  #Create one for the session
  Deps.autorun ->
    @name 'touch projectStatus'
    projectId = Session.get("projectId")
    return unless projectId
    Meteor.call "touchProjectStatus", Session.id, projectId,
      isHangout: Session.get("isHangout")
      hangoutUrl: Session.get('hangoutUrl')
      hangoutId: Session.get('hangoutId')

  #Make sure it's alive.
  #XXX: Is this obsoleted by session hooks?
  Meteor.setInterval ->
    projectId = Session.get "projectId"
    return unless projectId
    Meteor.call "touchProjectStatus", Session.id, projectId
  , 2*1000

  Deps.autorun ->
    @name 'set location'
    projectId = Session.get("projectId")
    return unless projectId and MadEye.fileLoader and MadEye.editorState
    lineNumber = MadEye.editorState.editor?.lineNumber || 1
    Meteor.call "touchProjectStatus", Session.id, projectId,
      filePath: MadEye.fileLoader.editorFilePath
      lineNumber: lineNumber
      connectionId: MadEye.editorState.connectionId

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
    MadEye.fileTree.setSessionPaths sessionPaths

  #Invalidate sessionsDep on important changes
  #TODO: Use fields: to limit watching to filePath.
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

  Deps.autorun ->
    @name 'Follow user'
    leaderId = Session.get 'leaderId'
    return unless leaderId
    log.info "Following connectionId #{leaderId}"
    gotoUser connectionId:leaderId

@gotoUser = ({connectionId}) ->
  theirProjectStatus = ProjectStatuses.findOne({connectionId},
    {fields: {filePath:1, lineNumber:1} })
  filePath = theirProjectStatus?.filePath
  lineNumber = theirProjectStatus?.lineNumber
  log.trace "Going to user #{connectionId} at filePath #{filePath} line #{lineNumber}"
  editorFile = Files.findOne MadEye.editorState?.fileId
  if editorFile and editorFile.path == filePath
    #Already in that file, just go to the line number
    MadEye.editorState.gotoLine lineNumber
  else
    #Query params have to be passed in options.
    Router.go 'edit', {projectId: getProjectId(), filePath}, {query: {lineNumber}, hash: "L#{lineNumber}" }

@followUser = ({connectionId}) ->
   Session.set 'leaderId', connectionId

@unfollowUser = ->
   Session.set 'leaderId', null

