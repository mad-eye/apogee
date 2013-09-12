Meteor.publish 'features', ->
  self = this
  googleLoginPresent = !!Meteor.settings.googleSecret && !!Meteor.settings.googleClientId
  self.added 'features', 'googleLogin', {present: googleLoginPresent}
    
