#TODO: This is just the bone-headed extraction of code from edit.coffee.
#We should refactor it so that it doesn't have knowlege of DOM ids/etc.

#Takes httpResponse
makeNetworkError = (response) ->
  return null unless response?
  error = null
  if response.content?.error?
    error = JSON.parse(response.content).error
  else
    error =
      title: "Network Error"
      message: "We're sorry, but there was trouble with the network.  Please try again later."
  error.title ?= error.type ? response.statusCode #TODO: for now.  Eventually make it more understandable
  error.level = 'error'
  return error

handleNetworkError = (error, response) ->
  displayAlert makeNetworkError(response) ? { level: 'error', message: error.message }

# Must set editorState.file for fetchBody or save to work.
class EditorState
  constructor: (@editorId)->
    @contexts = new Meteor.deps._ContextSet()

  getEditor: ->
    editor = ace.edit @editorId
    editor.setTheme "ace/theme/eclipse"
    return editor

  getEditorBody : ->
    @getEditor()?.getValue()

  getFileUrl : ->
    url = Meteor.settings.public.azkabanUrl + "/project/#{Projects.findOne()._id}/file/#{@file._id}"
    url

  setPath: (filePath) ->
    return if filePath == @filePath
    @filePath = filePath
    @contexts.invalidateAll()

  setLine: (@lineNumber) ->

  getPath: () ->
    @contexts.addCurrentContext()
    return @filePath

  revertFile: (callback) ->
    @getEditor().setValue("")
    Meteor.http.get "#{@getFileUrl()}?reset=true", (error,response) =>
      if error
        handleNetworkError error, response 
        callback(error)
      @file.modified = false
      @file.save()
      callback()
      Meteor.setTimeout =>
        @getEditor().navigateFileStart()
      ,0

  loadFile: (file) ->
    #console.log "Loading file", file
    @file = file
    sharejs.open file._id, "text2", "#{Meteor.settings.public.bolideUrl}/channel", (error, doc) =>
      try
        handleShareError error if error?
        editor = @getEditor()
        @doc?.detach_ace?()
        @doc = doc
        #TODO: Extract this into its own autorun block
        if mode = file.aceMode()
          Mode = undefined
          try
            Mode = require("ace/mode/#{mode}").Mode
            editor.getSession().setMode(new Mode())
          catch e
            jQuery.getScript "/ace/mode-#{mode}.js", =>
              Mode = require("ace/mode/#{mode}").Mode
              editor.getSession().setMode(new Mode())

        unless doc.version?
          #This seems to be a spurious case when the file is opened twice quickly.
          console.error "Found null doc version for file #{@file._id}"
          return
        if doc.version > 0
          unless doc.editorAttached
            doc.attach_ace editor
          else
            console.error "EDITOR ALREADY ATTACHED"
          doc.on 'change', (op) ->
            file.update {modified: true}
          editor.navigateFileStart() unless doc.cursor
          doc.emit "cursors"
        else
          editor.setValue "Loading..."
          #TODO figure out why this sometimes gets stuck on..
          #editor.setReadOnly true
          Meteor.http.get @getFileUrl(), timeout:5*1000, (error,response) =>
            if error
              handleNetworkError error, response
            else
              if doc == @doc #Safety for multiple loadFiles running simultaneously
                editor = @getEditor()
                doc.attach_ace editor
                editor.navigateFileStart() unless doc.cursor
                doc.on 'change', (op) ->
                  file.update {modified: true}
                  doc.emit "cursors" #TODO: This should be handled in ShareJS
      catch e
        #TODO: Handle this better.
        console.error e




  #callback: (err) ->
  save : (callback) ->
    #console.log "Saving file #{@file?._id}"
    self = this #The => doesn't work for some reason with the PUT callback.
    contents = @getEditorBody()
    file = @file
    return unless @file.modified
    Meteor.http.put @getFileUrl(), {
      data: {contents: contents}
      headers: {'Content-Type':'application/json'}
      timeout: 5*1000
    }, (error,response) ->
      if error
        handleNetworkError error, response
      else
        #XXX: Are we worried about race conditions if there were modifications after the save button was pressed?
        file.update {modified: false}
      callback(error)


