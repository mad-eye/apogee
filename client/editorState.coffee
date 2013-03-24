#TODO: This is just the bone-headed extraction of code from edit.coffee.
#We should refactor it so that it doesn't have knowlege of DOM ids/etc.

#Takes httpResponse
handleNetworkError = (error, response) ->
  err = response.content?.error ? error
  console.error "Network Error:", err.message
  Metrics.add
    level:'error'
    message:'networkError'
    error: err.message
  transitoryIssues.set 'networkIssues', 10*1000
  return err

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

  getFileUrl : (file)->
    Meteor.settings.public.azkabanUrl + "/project/#{Projects.findOne()._id}/file/#{file._id}"

  setPath: (filePath) ->
    return if filePath == @filePath
    @filePath = filePath
    @contexts.invalidateAll()

  setLine: (@lineNumber) ->

  getPath: () ->
    @contexts.addCurrentContext()
    return @filePath

  revertFile: (callback) ->
    unless @doc and @file
      Metrics.add
        level:'warn'
        message:'revertFile with null @doc'
        fileId: @file?._id
        filePath: @file?.path
      console.warn("revert called, but no doc selected")
      callback "No doc or no file"
    file = @file
    Meteor.http.get "#{@getFileUrl(file)}?reset=true", (error,response) =>
      if error
        handleNetworkError error, response
        callback(error)
      file.update modified:false
      #TODO this was in the timeout block below, check to make sure there's no problems
      callback()
      Meteor.setTimeout =>
        @getEditor().navigateFileStart()
      ,0

  #detach any existing docs and load appropriate ace modes
  setupAce: (editor, file)->
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

  checkDocValidity: (doc)->
    unless doc.version?
      #This seems to be a spurious case when the file is opened twice quickly.
      Metrics.add
        level:'warn'
        message:'shareJsError'
        fileId: @file._id
        filePath: @file?.path
        error: 'Found null doc version'
      console.error "Found null doc version for file #{@file._id}"
    return doc.version?

  attachAce: (doc)->
    file = @file
    unless doc.editorAttached
      doc.attach_ace @getEditor()
      doc.on 'change', (op) ->
        file.update {modified: true}
      doc.on 'warn', (data) =>
        Metrics.add
          level:'warn'
          message:'shareJsError'
          fileId: file._id
          filePath: file?.path
          error: data
      @getEditor().navigateFileStart() unless doc.cursor #why unless doc.cursor
      doc.emit "cursors"
    else
      Metrics.add
        level:'warn'
        message:'shareJsError'
        fileId: file._id
        filePath: file?.path
        error: 'Editor already attached'
      console.error "EDITOR ALREADY ATTACHED"

  clearDoc: ->
    @doc?.detach_ace?()
    @doc = null

  #callback: (error) ->
  loadFile: (@file, callback) ->
    #console.log "Loading file", file
    editor = @getEditor()
    Metrics.add
      message:'loadFile'
      fileId: file?._id
      filePath: file?.path
    Session.set "editorIsLoading", true
    sharejs.open file._id, "text2", "#{Meteor.settings.public.bolideUrl}/channel", (error, doc) =>
      unless file == @file #abort if we've loaded another file
        console.log "Loading file #{@file._id} overriding #{file._id}"
        return callback?(true)
      try
        #TODO something like cursorPositions.setMyPosition(@doc.name)
        #TODO: Extract this into its own autorun block
        return callback?(handleShareError error) if error?
        @clearDoc()
        return callback?(true) unless @checkDocValidity(doc)
        @setupAce(editor, file)
        if doc.version > 0
          @attachAce(doc)
          @doc = doc
          Session.set "editorIsLoading", false
          callback?()
        else
          #TODO figure out why this sometimes gets stuck on..
          #editor.setReadOnly true
          Meteor.http.get @getFileUrl(file), timeout:5*1000, (error,response) =>
            return callback? handleNetworkError error, response if error
            return callback?(true) unless file == @file #Safety for multiple loadFiles running simultaneously
            @doc = doc
            @attachAce(doc)
            Session.set "editorIsLoading", false
            callback? null

      catch e
        #TODO: Handle this better.
        console.error "Error in loading file: #{e.message}:", e
        Metrics.add
          level:'error'
          message:'shareJsError'
          fileId: file._id
          filePath: file?.path
          error: e.message
        callback? e

  #callback: (err) ->
  save : (callback) ->
    #console.log "Saving file #{@file?._id}"
    Metrics.add
      message:'saveFile'
      fileId: @file?._id
      filePath: @file?.path #don't want reactivity
    self = this #The => doesn't work for some reason with the PUT callback.
    contents = @getEditorBody()
    file = @file
    return unless @file.modified
    Meteor.http.put @getFileUrl(file), {
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


