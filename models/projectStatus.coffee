class ProjectStatus
  constructor: (rawJSON) ->
    _.extend(@, rawJSON)

@ProjectStatuses = new Meteor.Model("projectStatus", ProjectStatus)

#return a map between file paths and open sharejs session ids
if Meteor.isClient
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
    projectStatus.update {filePath: editorState.getPath(), connectionId: editorState.getConnectionId()}


