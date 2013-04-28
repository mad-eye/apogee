Template.interview.helpers
  projectId: ->
    Projects.findOne()?._id

  scratchPads: ->
    ScratchPads.find()

  selected: ->
    if editorState.filePath == @path
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
