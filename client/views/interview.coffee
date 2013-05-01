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
    try
      scratchPad.save()
      Meteor.Router.to "/interview/#{projectId}/#{filename}"
    catch e
      alert e.message

Template.interview.rendered = ->
  return if Dropzone.forElement "#dropzone"
  $("#dropzone").dropzone
    paramName: "file"
    accept: (file, done)->
      pad = new MadEye.ScratchPad
      pad.path = file.name
      pad.projectId = Session.get "projectId"
      try
        pad.save()
        @options.url = "#{Meteor.settings.public.azkabanUrl}/file-upload/#{pad._id}"
        done()
      catch e
        alert e.message
        done(e.message)
    url: "bogus" #can't initialize a dropzone w/o a url, overwritten in accept function above
