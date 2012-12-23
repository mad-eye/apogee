# XXX: These should probably go somewhere more obvious public, like models?
# error = _id, type, message
Errors = new Meteor.Collection null

handleError = (error, result) ->
  err = makeNetworkError(result) ? error
  Errors.insert err

makeNetworkError = (result) ->
  return null unless result?
  error = JSON.parse(result?.content)?.error
  error ?=
    type: result.statusCode
    message: result.error?.message
  error

