class MadEye.ScratchPad extends MadEye.File
  save: ->
    unless @path
      return "You must specify a path"
    if !@_id and ScratchPads.findOne {path: @path, projectId: Session.get "projectId"}
      return "A file with that path already exists"
    super()

@ScratchPads = new Meteor.Collection 'scratchPads', transform: (doc) ->
  new MadEye.ScratchPad doc

MadEye.ScratchPad.prototype.collection = @ScratchPads
