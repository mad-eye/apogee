class Output extends MadEye.Model

@Outputs = new Meteor.Collection "outputs", transform: (doc) ->
  new Output doc

Output.prototype.collection = @Outputs
