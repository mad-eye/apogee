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
    type: result.statusCode
    message: result.error?.message
  error.title = error.type #TODO: for now.  Eventually make it more understandable
  error.level = 'error'
  console.log "Made error", error
  return error

