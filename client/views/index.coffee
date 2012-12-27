Handlebars.registerHelper "isHomePage", ->
  return "home" == Meteor.Router._page

displayAlert = (level, title, message) ->
  html = Template.alert {
    level: level
    title: title
    message: message
  }
  $('#alertBox').append html


