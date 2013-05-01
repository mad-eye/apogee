class MadEye.ScratchPad extends MadEye.File
  save: ->
    if ScratchPads.findOne {path: @path, projectId: Session.get "projectId"}
      return alert "A file with that path already exists"
    else if not @path? or @path == ""
      return alert "You must specify a path"
    super()

@ScratchPads = new Meteor.Collection 'scratchPads', transform: (doc) ->
  new MadEye.ScratchPad doc

MadEye.ScratchPad.prototype.collection = @ScratchPads
