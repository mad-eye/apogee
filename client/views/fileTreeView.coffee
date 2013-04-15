do ->
  Template.fileTree.helpers
    files : ->
      Files.find({}, {sort: {orderingPath:1} } )

    isVisible: ->
      fileTree.isVisible @path

    fileEntryClass : ->
      clazz = "fileTree-item"
      if @isDir
        clazz += " directory " + if fileTree.isOpen @path then "open" else "closed"
      else
        clazz += " file"
      clazz += " level" + @depth
      clazz += " selected" if Session.equals 'selectedFileId', @_id
      clazz += " modified" if @modified
      return clazz

    usersInFile: (file) ->
      projectId = Session.get "projectId"
      sessionIds = fileTree.getSessionsInFile file.path
      return unless sessionIds
      users = null
      Deps.nonreactive ->
        users = ProjectStatuses.find(sessionId: {$in: sessionIds}).map (status) ->
          destination = "/edit/#{projectId}/#{file.path}#S#{status.connectionId}"
          {img: "/images/#{USER_ICONS[status.iconId]}", destination}
      return users

    projectName : ->
      Projects.findOne(Session.get "projectId")?.name ? "New project"

  # Select file
  Template.fileTree.events
    'click li.fileTree-item' : (event) ->
      file = Files.findOne event.currentTarget.id
      fileTree.select file


    #'click img.fileTreeUserIcon': (event) ->
      #event.stopPropagation()
      #Meteor.Router.to event.toElement.attributes.destination.value

  #Template.fileTree.rendered = ->
    #console.log "Rendered fileTree"

  Meteor.startup ->
    window.fileTree = new FileTree

    #Populate fileTree with ProjectStatuses filePath
    sessionsDep = new Deps.Dependency

    Deps.autorun ->
      projectId = Session.get "projectId"
      Deps.depend sessionsDep
      sessionPaths = {}
      Deps.nonreactive ->
        statuses = ProjectStatuses.find {projectId}
        for status in statuses
          continue unless status.filePath
          sessionPaths[status.sessionId] = status.filePath
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
            # console.log "ADDED", id, fields
            sessionsDep.changed()

          changed: (id, fields)->
            # console.log "CHANGED", id, fields if fields.filePath?
            sessionsDep.changed() if fields.filePath?

          removed: (id, fields)->
            # console.log "REMOVED", id, fields
            sessionsDep.changed()

