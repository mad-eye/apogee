Template.fileTree.created = ->
  MadEye.rendered 'fileTree'
  #Sometimes the resize happens before everything is ready.
  #It's idempotent and cheap, so do this for safety's sake.
  Meteor.setTimeout ->
    resizeEditor()
  , 100

Template.fileTree.rendered = ->
  resizeEditor()

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
    fileId = event.currentTarget.id
    file = Files.findOne(fileId)
    return unless file
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
    warnFirefoxHangout()
    #Page.js tries to handle this, but gets the port wrong.
    event.stopPropagation()
    window.location = event.target.href

  #'click img.fileTreeUserIcon': (event) ->
    #event.stopPropagation()
    #Router.go 'edit', projectId: getProjectId(), sessionId: event.toElement.attributes.destination.value

@warnFirefoxHangout = ->
  if "Firefox" == BrowserDetect.browser and BrowserDetect.version < 22
    confirm "Older versions of Firefox have performance issues in MadEye Hangouts.  For best experience, upgrade to the latest version of Firefox."

