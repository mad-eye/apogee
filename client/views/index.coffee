Handlebars.registerHelper "isHomePage", ->
  return "home" == Meteor.Router._page

Template.home.events
  'click #submitEmailButton' : (event) ->
    event.stopImmediatePropagation()
    event.preventDefault()
    emailAddr = $('#emailInput').val()
    console.log "Found email address", emailAddr
    
