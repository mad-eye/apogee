#Add the home controller here

Accounts.ui.config
  requestPermissions:
    github: ['user', 'repo']
  passwordSignupFields: 'USERNAME_AND_OPTIONAL_EMAIL'

Template.home.events
  #'click #submitEmailButton' : (event) ->
  'submit #signupForm' : (event) ->
    emailAddr = $('#emailInput').val()
    if emailAddr == ''
      return false
    sendNotifyEmail emailAddr
    $('#emailInput').val('')
    displayAlert('info', "You're in the loop!", "We'll notify #{emailAddr} as soon as we have news.")
    return false

sendNotifyEmail = (email) ->
  console.log "sendNotifyEmail #{email}"
  Meteor.call 'sendNotifyEmail', email, (error, result) ->
    return error ? result
  
