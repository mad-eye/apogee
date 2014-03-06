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
      name: Meteor.user()?.name
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

  Deps.autorun ->
    @name 'set sessionPaths'
    projectId = Session.get "projectId"
    sessionPaths = {}
    ProjectStatuses.find({projectId}, {fields: {sessionId:1, filePath: 1}}).forEach (status) ->
      sessionPaths[status.sessionId] = status.filePath if status.filePath
    log.trace "Setting sessionPaths from autorun", sessionPaths
    MadEye.fileTree.setSessionPaths sessionPaths

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

