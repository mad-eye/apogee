do ->
  Handlebars.registerHelper "isHomePage", ->
    return "home" == Meteor.Router._page or "home2" == Meteor.Router._page

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

