#Add the home controller here

Template.getStarted.events
  #'click #submitEmailButton' : (event) ->
  'submit #signupForm' : (event) ->
    emailAddr = $('#emailInput').val()
    if emailAddr == ''
      return false
    newsletterEmail = new NewsletterEmail email: emailAddr
    newsletterEmail.save()
    $('#emailInput').val('')
    $('#signupFeedback').css('display', 'inline')
    #displayAlert
      #level:'info'
      #title: "You're in the loop!"
      #message: "We'll notify #{emailAddr} as soon as we have news."
    return false

  
