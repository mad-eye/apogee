do ->
  Handlebars.registerHelper "isHomePage", ->
    return "home" == Meteor.Router._page

  Template.alerts.errors = ->
    return Errors.find().fetch()

  Template.alerts.events
    'click button.error-close' : (event) ->
      Errors.remove event.currentTarget.id

displayAlert = (level, title, message) ->
  html = Template.alert {
    level: level
    title: title
    message: message
  }
  $('#alertBox').append html


