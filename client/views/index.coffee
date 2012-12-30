do ->
  Handlebars.registerHelper "isHomePage", ->
    return "home" == Meteor.Router._page

displayAlert = (alert) ->
  return unless alert?
  html = Template.alert {
    level: alert.level
    title: alert.title
    message: alert.message
  }
  $('#alertBox').append html

