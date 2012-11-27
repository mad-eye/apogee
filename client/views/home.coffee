#Add the home controller here

Accounts.ui.config
  requestPermissions:
    github: ['user', 'repo']
  passwordSignupFields: 'USERNAME_AND_OPTIONAL_EMAIL'

Template.home.events
  'click #submitEmailButton' : (event) ->
    emailAddr = $('#emailInput').val()
    if emailAddr == ''
      #event.stopImmediatePropagation()
      event.preventDefault()
    
