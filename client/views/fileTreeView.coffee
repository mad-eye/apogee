log = new Logger 'fileTreeView'

Template.fileTree.rendered = ->
  MadEye.rendered 'fileTree'
  Meteor.setTimeout ->
    windowSizeChanged()
  , 100

Template.fileTree.helpers
  files : ->
    Files.find {}, {sort: {orderingPath:1} }

  isVisible: ->
    MadEye.fileTree.isVisible @path

  fileEntryClass : ->
    clazz = "fileTree-item"
    if @isDir
      clazz += " directory "
      if MadEye.fileTree.isOpen @path
        if @isLoading
          clazz += 'loading'
        else
          clazz += "open"
      else
        clazz += "closed"
    else if @scratch
      clazz += " scratch"
    else
      clazz += " file"
    clazz += " level" + @depth
    clazz += " selected" if Session.equals 'selectedFileId', @_id
    clazz += " modified" if @modified
    return clazz

  usersInFile: (file) ->
    projectId = Session.get "projectId"
    sessionIds = MadEye.fileTree.getSessionsInFile file.path
    return unless sessionIds

    users = ProjectStatuses.find(
      {sessionId: {$in: sessionIds}},
      {fields: {sessionId:1, connectionId:1}}
    ).map (status) ->
      return unless status.connectionId
      if status.sessionId == Session.id
        #The user's own
        iconClass = "user_selection cursor_color_00"
      else
        shareIndex = sharejs.getIndexForConnection status.connectionId
        iconClass = "foreign_selection foreign_selection_#{shareIndex} cursor_color_#{shareIndex}"
      return {iconClass, connectionId:status.connectionId}

    users = (user for user in users when user)
    return users

  projectName : ->
    Projects.findOne(Session.get "projectId")?.name ? "New project"

# Select file
Template.fileTree.events
  'click li.fileTree-item' : (event) ->
    fileId = event.currentTarget.id
    file = Files.findOne(fileId)
    return unless file
    log.trace "Going to file", file.path
    MadEye.fileTree.toggle file.path
    MadEye.fileLoader.loadId = event.currentTarget.id

  "click #addFileButton": (event)->
    filename = prompt "Enter a filename"
    return unless filename?
    file = new MadEye.File
    file.scratch = true
    projectId = Session.get "projectId"
    file.projectId = projectId
    file.path = filename
    try
      file.save()
      MadEye.fileLoader.loadId = file._id
    catch e
      alert e.message

  "click .hangout-link": (event) ->
    #Page.js tries to handle this, but gets the port wrong.
    event.stopPropagation()
    window.location = event.target.href

  'click .fileTreeUserIcon': (event) ->
    event.stopPropagation()
    connectionId = event.target.dataset['connectionid']
    theirProjectStatus = ProjectStatuses.findOne({connectionId})
    filePath = theirProjectStatus?.filePath
    lineNumber = theirProjectStatus?.lineNumber
    log.trace "Going to user #{connectionId} at filePath #{filePath} line #{lineNumber}"
    editorFile = Files.findOne MadEye.editorState?.fileId
    #TODO this logic probably doesn't belong in the view..  Extract this to a service
    if editorFile and editorFile.path == filePath
      #Already in that file, just go to the line number
      MadEye.editorState.gotoLine lineNumber
    else
      #Query params have to be passed in options.
      Router.go 'edit', {projectId: getProjectId(), filePath}, {query: {lineNumber}, hash: "L#{lineNumber}" }
