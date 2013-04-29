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

Template.interview.events
  "click li": (event)->
    editorState.setPath event.toElement.id

Template.interview.rendered = ->
  return if Dropzone.forElement "#dropzone"
  $("#dropzone").dropzone
    paramName: "file"
    accept: (file, done)->
      pad = new MadEye.ScratchPad
      pad.path = file.name
      pad.projectId = Session.get "projectId"
      pad.save()
      @options.url = "#{Meteor.settings.public.azkabanUrl}/file-upload/#{pad._id}"
      done()
    url: "bogus" #can't initialize a dropzone w/o a url, overwritten in accept function above