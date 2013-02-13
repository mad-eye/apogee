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

  loadFile: (file, bolideUrl) ->
    sharejs.open file._id, "text2", bolideUrl, (error, doc) =>
      editor = @getEditor()
      @doc?.detach_ace?()
      @doc = doc
      if mode = file.aceMode()
        jQuery.getScript "/packages/meteor-sharejs/mode-#{mode}.js", =>
          Mode = require("ace/mode/#{mode}").Mode
          editor.getSession().setMode(new Mode())

      if doc.version > 0
        doc.attach_ace editor
        doc.on 'change', (op) ->
          file.update {modified: true}
        doc.emit "cursors"
      else
        editor.setValue "Loading..."
        #TODO figure out why this sometimes gets stuck on..
        #editor.setReadOnly true
        #TODO handle errors
        @file = file
        Meteor.http.get @getFileUrl(), (error,response) =>
          if error
            handleNetworkError error, response
          else
            if doc == @doc #Safety for multiple loadFiles running simultaneously
              doc.attach_ace @getEditor()
              doc.on 'change', (op) ->
                file.update {modified: true}
              doc.emit "cursors" #TODO: This should be handled in ShareJS


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


