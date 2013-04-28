class MadEye.ScratchPad extends MadEye.Model
  constructor: (data) ->
    super data

@ScratchPads = new Meteor.Collection 'scratchPads', transform: (doc) ->
  new MadEye.ScratchPad doc

MadEye.ScratchPad.prototype.collection = @ScratchPads
