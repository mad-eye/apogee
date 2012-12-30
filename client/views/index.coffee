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

makeNetworkError = (result) ->
  return null unless result?
  error = JSON.parse(result?.content)?.error
  error ?=
    level: 'error'
    type: result.statusCode
    message: result.error?.message
  error

