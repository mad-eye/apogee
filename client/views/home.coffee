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
    newsletterEmail = new NewsletterEmail email: emailAddr
    newsletterEmail.save()
    $('#emailInput').val('')
    displayAlert
      level:'info'
      title: "You're in the loop!"
      message: "We'll notify #{emailAddr} as soon as we have news."
    return false

  
