#TODO: This is just the bone-headed extraction of code from edit.coffee.
#We should refactor it so that it doesn't have knowlege of DOM ids/etc.

#Takes httpResponse
makeNetworkError = (response) ->
  return null unless response?
  error = JSON.parse(response?.content)?.error
  error ?=
    type: response.statusCode
    message: response.error?.message
  error.title = error.type #TODO: for now.  Eventually make it more understandable
  error.level = 'error'
  console.log "Made error", error
  return error

handleNetworkError = (error, response) ->
  displayAlert makeNetworkError(response) ? { level: 'error', message: error.message }

# Must set editorState.file for fetchBody or save to work.
class EditorState
  constructor: (@editorId)->

  getEditor: ->
    ace.edit @editorId

  getEditorBody : ->
    @getEditor()?.getValue()

  getFileUrl : ->
    settings = Settings.findOne()
    url = settings.azkabanUrl + "/project/#{Projects.findOne()._id}/file/#{@file._id}"
    console.log url
    url

  fetchBody : (callback) ->
    Meteor.http.get @getFileUrl(), (error,response)->
      if error
        handleNetworkError error, response
      else
        callback JSON.parse(response.content).body

  #callback: (err) ->
  save : (callback) ->
    self = this #The => doesn't work for some reason with the PUT callback.
    contents = @getEditorBody()
    return unless @file.modified
    Meteor.http.call "PUT", @getFileUrl(), {
      data: {contents: contents}
      headers: {'Content-Type':'application/json'}
    }, (error,response) ->
      if error
        handleNetworkError error, response
      else
        #XXX: Are we worried about race conditions if there were modifications after the save button was pressed?
        self.file.update {modified: false}
      callback(error)


