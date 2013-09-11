Handlebars.registerHelper "isHomePage", ->
  return Meteor.Router._page in ["home", "home2", "getStarted"]

Handlebars.registerHelper "isHangout", ->
  Session.get "isHangout"

@displayAlert = (alert) ->
  return unless alert?
  html = Template.alert {
    level: alert.level
    title: alert.title
    message: alert.message
  }
  $('#alertBox').append html

Template.signin.helpers
  hasGoogleLogin: hasGoogleLogin
