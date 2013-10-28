log = new MadEye.Logger 'accounts'

Meteor.publish 'userData', ->
  return Meteor.users.find {_id: this.userId}, fields:
    name: 1
    email: 1
    type: 1

Accounts.onCreateUser (options, user) ->
  log.debug "Creating user", user
  user.type = switch
    when options.anonymous then 'anonymous'
    when user.services?.google then 'google'
    when user.services?.password then 'password'

  switch user.type
    when 'google'
      user.name = user.services.google.name
      user.email = user.services.google.email
    when 'password'
      #TODO: Make this a bit tighter
      user.email = user.emails[0].address
      #TODO: Parse; use user.profile.name ?
      user.name = user.username || user.email


  Workspaces.insert userId: user._id
  return user

Meteor.startup ->
  googleConfig = Accounts.loginServiceConfiguration.findOne(service:'google')
  return if googleConfig
  unless Meteor.settings.googleSecret
    console.error "Missing googleSecret; cannot configure"
    return
  unless Meteor.settings.googleClientId
    console.error "Missing googleClientId; cannot configure"
    return
  Accounts.loginServiceConfiguration.insert
    service: 'google'
    clientId: Meteor.settings.googleClientId
    secret: Meteor.settings.googleSecret
