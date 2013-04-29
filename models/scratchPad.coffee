class MadEye.ScratchPad extends MadEye.File

@ScratchPads = new Meteor.Collection 'scratchPads', transform: (doc) ->
  new MadEye.ScratchPad doc

MadEye.ScratchPad.prototype.collection = @ScratchPads
