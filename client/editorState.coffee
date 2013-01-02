#TODO: This is just the bone-headed extraction of code from edit.coffee.
#We should refactor it so that it doesn't have knowlege of DOM ids/etc.

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

handleNetworkError = (error, result) ->
  displayAlert makeNetworkError(result) ? { level: 'error', message: error.message }

# Must set editorState.file for fetchBody or save to work.
class EditorState
  constructor: (@editorId)->

  getEditor: ->
    ace.edit @editorId

  getEditorBody : ->
    getEditor()?.getValue()

  getFileUrl : ()->
    settings = Settings.findOne()
    url = "http://#{settings.httpHost}:#{settings.httpPort}"
    url = "#{url}/project/#{Projects.findOne()._id}/file/#{@file._id}"
    console.log url
    url

  fetchBody : (callback) ->
    Meteor.http.get @getFileUrl(), (error,result)->
      if error
        handleNetworkError error, result
      else
        callback JSON.parse(result.content).body

  save : ()->
    contents = @getEditorBody()
    return unless @file.modified
    Meteor.http.call "PUT", @getFileUrl(), {
      data: {contents: contents}
      headers: {'Content-Type':'application/json'}
    }, (error,result)->
      if error
        handleNetworkError error, result
      else
        #XXX: Are we worried about race conditions if there were modifications after the save button was pressed?
        @file.update {modified: false}


