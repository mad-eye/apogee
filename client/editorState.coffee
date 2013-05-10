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

class EditorState
  constructor: (@editorId)->
    @_deps = {}
    @editor = new ReactiveAce
    
  depend: (key) ->
    @_deps[key] ?= new Deps.Dependency
    @_deps[key].depend()

  changed: (key) ->
    @_deps[key]?.changed()

  attach: ->
    @editor.attach @editorId

  getEditor: ->
    @depend 'path'
    @editor.attach @editorId
    newEditor = @editor._getEditor()
    return newEditor

  getFileUrl : (fileId)->
    Meteor.settings.public.azkabanUrl + "/project/#{Projects.findOne(Session.get 'projectId')._id}/file/#{fileId}"

  setCursorDestination: (connectionId)->
    @cursorDestination = connectionId

  setLine: (@lineNumber) ->

  revertFile: (callback) ->
    unless @doc and @fileId
      Metrics.add
        level:'warn'
        message:'revertFile with null @doc'
        fileId: @fileId
      console.warn("revert called, but no doc selected")
      return callback? "No doc or no file"
    Events.record("revert", {file: @path, projectId: Session.get "projectId"})
    @working = true
    Meteor.http.get "#{@getFileUrl(@fileId)}?reset=true", (error,response) =>
      @working = false
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
        fileId: @fileId
        error: 'Found null doc version'
      console.error "Found null doc version for file #{@fileId}"
    return doc.version?

  attachAce: (doc)->
    fileId = @fileId
    unless doc.editorAttached
      doc.attach_ace @editor._getEditor()
      @editor.newLineMode = "auto"
      doc.on 'warn', (data) =>
        Metrics.add
          level:'warn'
          message:'shareJsError'
          fileId: fileId
          error: data
      @getEditor().navigateFileStart() unless doc.cursor #why unless doc.cursor
      doc.emit "cursors"
    else
      Metrics.add
        level:'warn'
        message:'shareJsError'
        fileId: fileId
        error: 'Editor already attached'
      console.error "EDITOR ALREADY ATTACHED"

  #callback: (error) ->
  loadFile: (file, callback) ->
    #console.log "Loading file", file
    @fileId = fileId = file._id
    editor = @getEditor()
    @doc?.detach_ace?()
    @doc = null
    Metrics.add
      message:'loadFile'
      fileId: fileId
      filePath: file.path
    @loading = true
    sharejs.open fileId, "text2", "#{Meteor.settings.public.bolideUrl}/channel", (error, doc) =>
      @connectionId = doc.connection.id
      unless fileId == @fileId #abort if we've loaded another file
        console.log "Loading file #{@fileId} overriding #{fileId}"
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
          Meteor.http.get @getFileUrl(fileId), timeout:5*1000, (error,response) =>
            return callback? handleNetworkError error, response if error
            return callback?(true) unless fileId == @fileId #Safety for multiple loadFiles running simultaneously
            @doc = doc
            @attachAce(doc)
            if response.data?.checksum?
              file.update {checksum:response.data.checksum}
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
          error: e.message
        callback? e

  #callback: (err) ->
  save : (callback) ->
    console.log "Saving file #{@fileId}"
    Events.record("save", {file: @fileId, projectId: Session.get "projectId"})
    Metrics.add
      message:'saveFile'
      fileId: @fileId
    editorChecksum = @editor.checksum
    file = Files.findOne @fileId
    return if file.checksum == editorChecksum
    @working = true
    Meteor.http.put @getFileUrl(@fileId), {
      data: {contents: @editor.value}
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
      @changed name
  Object.defineProperty EditorState.prototype, name, descriptor

EditorState.addProperty 'rendered', '_rendered', '_rendered'
EditorState.addProperty 'path', '_path', '_path'
EditorState.addProperty 'fileId', '_fileId', '_fileId'
#@loading: if a file is loading
EditorState.addProperty 'loading', '_loading', '_loading'
#@working: if a file is saving/reverting
EditorState.addProperty 'working', '_working', '_working'
#shareJs connection Id
EditorState.addProperty 'connectionId', '_connectionId', '_connectionId'


@EditorState = EditorState

Meteor.startup ->
  Meteor.autorun ->
    file = Files.findOne(editorState?.fileId)
    return unless file?.checksum?
    checksum = editorState.editor.checksum
    return unless checksum?
    #console.log "isModified: #{checksum} vs #{file.checksum}"
    modified = checksum != file.checksum
    file.update {modified}


