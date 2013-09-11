@Features = new Meteor.Collection 'features'
Deps.autorun ->
  Meteor.subscribe 'features'

@hasGoogleLogin = ->
  Features.findOne('googleLogin')?.present
