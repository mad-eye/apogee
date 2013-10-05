class ActiveDirectory extends MadEye.Model

@ActiveDirectories = new Meteor.Collection "activeDirectories", transform: (doc) ->
  new ActiveDirectory doc


ActiveDirectory.prototype.collection = @ActiveDirectories
