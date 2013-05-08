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
    @renderedDep = new Deps.Dependency
    @tabsDep = new Deps.Dependency

    @_deps = {}
    @editor = new ReactiveAce
    
  depend: (key) ->
    @_deps[key] ?= new Deps.Dependency
    @_deps[key].depend()

  change: (key) ->
    @_deps[key]?.changed()

  attach: ->
    @editor.attach @editorId

  getEditor: ->
    @depend 'path'
    @editor.attach @editorId
    newEditor = @editor._getEditor()
    return newEditor

  getFileUrl : (file)->
    Meteor.settings.public.azkabanUrl + "/project/#{Projects.findOne(Session.get 'projectId')._id}/file/#{file._id}"

  setCursorDestination: (connectionId)->
    @cursorDestination = connectionId

  setLine: (@lineNumber) ->

  connectionIdDep = new Deps.Dependency

  setConnectionId: (connectionId) ->
    return if connectionId == @connectionId
    @connectionId = connectionId
    connectionIdDep.changed()

  getConnectionId: ()->
    Deps.depend connectionIdDep
    @connectionId

  revertFile: (callback) ->
    unless @doc and @file
      Metrics.add
        level:'warn'
        message:'revertFile with null @doc'
        fileId: @file?._id
        filePath: @file?.path
      console.warn("revert called, but no doc selected")
      return callback? "No doc or no file"
    file = @file
    Events.record("revert", {file: @file.path, projectId: Session.get "projectId"})
    Meteor.http.get "#{@getFileUrl(file)}?reset=true", (error,response) =>
      if error
        handleNetworkError error, response
        callback?(error)
        return
      #TODO this was in the timeout block below, check to make sure there's no problems
      callback?()
      Meteor.setTimeout =>
        @getEditor().navigateFileStart()
      ,0


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
      @getEditor().getSession().getDocument().setNewLineMode("auto")
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

  #callback: (error) ->
  loadFile: (@file, callback) ->
    #console.log "Loading file", file
    editor = @getEditor()
    @doc?.detach_ace?()
    @doc = null
    Metrics.add
      message:'loadFile'
      fileId: file?._id
      filePath: file?.path
    @loading = true
    sharejs.open file._id, "text2", "#{Meteor.settings.public.bolideUrl}/channel", (error, doc) =>
      @setConnectionId doc.connection.id
      unless file == @file #abort if we've loaded another file
        console.log "Loading file #{@file._id} overriding #{file._id}"
        return callback?(true)
      try
        #TODO: Extract this into its own autorun block
        return callback?(handleShareError error) if error?
        return callback?(true) unless @checkDocValidity(doc)
        if doc.version > 0
          @attachAce(doc)
          @doc = doc
          editorChecksum = MadEye.crc32 doc.getText()
          @loading = false
          # FIXME there's a better way to do this
          # we need to stop storing a stale file object on the editorState
          if file.modified_locally and file.checksum == editorChecksum
            @revertFile()
          callback?()
        #ask azkaban to fetch the file from dementor unless this is a scratch pad
        else unless file instanceof MadEye.ScratchPad
          #TODO figure out why this sometimes gets stuck on..
          #editor.setReadOnly true
          Meteor.http.get @getFileUrl(file), timeout:5*1000, (error,response) =>
            return callback? handleNetworkError error, response if error
            return callback?(true) unless file == @file #Safety for multiple loadFiles running simultaneously
            @doc = doc
            @attachAce(doc)
            if response.data?.checksum?
              @file.update {checksum:response.data.checksum}
            if response.data?.warning
              alert = response.data?.warning
              alert.level = 'warn'
              displayAlert alert
            @loading = false
            callback? null
        else #its a scratchPad
          @doc = doc
          @attachAce(doc)
          @loading = false
          callback?()

      catch e
        @loading = false
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
    console.log "Saving file #{@file?._id}"
    Events.record("save", {file: @file?.path, projectId: Session.get "projectId"})
    Metrics.add
      message:'saveFile'
      fileId: @file?._id
      filePath: @file?.path #don't want reactivity
    self = this #The => doesn't work for some reason with the PUT callback.
    contents = @editor.value
    editorChecksum = MadEye.crc32 contents
    file = @file
    return if @file.checksum == editorChecksum
    @working = true
    Meteor.http.put @getFileUrl(file), {
      data: {contents: contents}
      headers: {'Content-Type':'application/json'}
      timeout: 5*1000
    }, (error,response) =>
      if error
        handleNetworkError error, response
      else
        #XXX: Are we worried about race conditions if there were modifications after the save button was pressed?
        file.update {checksum:editorChecksum}
      @working = false
      callback(error)

EditorState.addProperty = (name, getter, setter) ->
  descriptor = {}
  if 'string' == typeof getter
    varName = getter
    getter = -> return @[varName]
  if getter
    descriptor.get = ->
      @depend name
      return getter.call(this)
  if 'string' == typeof setter
    varName = setter
    setter = (value) -> @[varName] = value
  if setter
    descriptor.set = (value) ->
      return if getter and value == getter.call this
      setter.call this, value
      @change name
  Object.defineProperty EditorState.prototype, name, descriptor

EditorState.addProperty 'isRendered', '_isRendered', '_isRendered'
EditorState.addProperty 'path', '_path', '_path'
#Editor is loading a file
EditorState.addProperty 'loading', '_loading', '_loading'
#Editor is saving/reverting
EditorState.addProperty 'working', '_working', '_working'


@EditorState = EditorState

Meteor.startup ->
  Meteor.autorun ->
    file = Files.findOne(path:editorState?.path)
    return unless file?.checksum?
    checksum = editorState.editor.checksum
    return unless checksum?
    #console.log "isModified: #{checksum} vs #{file.checksum}"
    modified = checksum != file.checksum
    file.update {modified}


