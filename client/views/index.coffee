do ->
  Handlebars.registerHelper "isHomePage", ->
    return "home" == Meteor.Router._page

  Template.alerts.errors = ->
    return Errors.find().fetch()

  Template.alerts.events
    'click button.error-close' : (event) ->
      Errors.remove event.currentTarget.id

