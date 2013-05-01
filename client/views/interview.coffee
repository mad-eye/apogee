Template.interview.helpers
  projectId: ->
    Projects.findOne()?._id

  scratchPads: ->
    ScratchPads.find()

  selected: ->
    if editorState.getPath() == @path
      "selected"
    else
      "unselected"

  path: ->
    @path

  fileId: ->
    ScratchPads.findOne(path: editorState.getPath())._id

  #XXX TODO copied w/ shame from fileTreeView.coffee
  usersInFile: (file)->
    projectId = Session.get "projectId"
    sessionIds = fileTree.getSessionsInFile file.path
    return unless sessionIds
    users = null
    Deps.nonreactive ->
      users = ProjectStatuses.find(sessionId: {$in: sessionIds}).map (status) ->
        {img: "/images/#{USER_ICONS[status.iconId]}"}
    return users


#XXX TODO: Copied from fileTreeView.coffee
Template.interview.events
  "click li": (event)->
    projectId = Session.get "projectId"
    filename = event.currentTarget.id
    Meteor.Router.to "/interview/#{projectId}/#{filename}"

  "click #addFileButton": (event)->
    filename = prompt "Enter a filename"
    scratchPad = new MadEye.ScratchPad
    projectId = Session.get "projectId"
    scratchPad.projectId = projectId
    scratchPad.path = filename
    validationError = scratchPad.save() #should mostly be empty
    if validationError
      alert validationError
    else
      Meteor.Router.to "/interview/#{projectId}/#{filename}"

Template.interview.rendered = ->
  return if Dropzone.forElement "#dropzone"
  $("#dropzone").dropzone
    paramName: "file"
    accept: (file, done)->
      pad = new MadEye.ScratchPad
      pad.path = file.name
      pad.projectId = Session.get "projectId"
      validationError = pad.save() #should mostly be empty.
      @options.url = "#{Meteor.settings.public.azkabanUrl}/file-upload/#{pad._id}"
      alert validationError if validationError
      done(validationError)
    url: "bogus" #can't initialize a dropzone w/o a url, overwritten in accept function above
