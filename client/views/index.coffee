Handlebars.registerHelper "isHomePage", ->
  return "home" == Meteor.Router._page

