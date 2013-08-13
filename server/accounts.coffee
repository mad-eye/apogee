Meteor.publish 'userData', ->
  #console.log "Publishing user", Meteor.users.findOne this.userId
  return Meteor.users.find {_id: this.userId}, fields:
    name: 1
    email: 1
    type: 1

Accounts.onCreateUser (options, user) ->
  user.type = switch
    when options.anonymous then 'anonymous'
    when user.services?.google then 'google'

  if user.type == 'google'
    user.name = user.services.google.name
    user.email = user.services.google.email

  return user
