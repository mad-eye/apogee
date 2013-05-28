do ->
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

@loginWithGoogle = ->
  Meteor.logout()
  Meteor.loginWithGoogle()

Template.topnav.helpers
  #TODO
  googleLoggedin: ->
    return false

Template.topnav.events
  "click .google": (e)->
    e.preventDefault()
    Meteor.logout()
    Meteor.loginWithGoogle()
