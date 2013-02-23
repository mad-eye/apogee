do ->
  Handlebars.registerHelper "isHomePage", ->
    return "home" == Meteor.Router._page

  isHangout = /hangout=true/.exec(document.location.href.split("?")[1])
  Handlebars.registerHelper "isHangout", ->
    isHangout

displayAlert = (alert) ->
  return unless alert?
  html = Template.alert {
    level: alert.level
    title: alert.title
    message: alert.message
  }
  $('#alertBox').append html

