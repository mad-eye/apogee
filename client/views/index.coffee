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

Template.topnav.helpers
  isLoggedIn: ->
    Meteor.user()?.services?.google?
    
  isLoggedOut: ->
    #We view 'loggedOut' to mean using an anonymous account
    not Meteor.user()?.services?