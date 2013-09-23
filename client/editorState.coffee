#Takes httpResponse
handleNetworkError = (error, response) ->
  err = response?.content?.error ? error
  console.error "Network Error:", err.message
  Metrics.add
    level:'error'
    message:'networkError'
    error: err.message
  MadEye.transitoryIssues.set 'networkIssues', 10*1000
  return err

#TODO: HACK: Move to a better place
os = (navigator.platform.match(/mac|win|linux/i) || ["other"])[0].toLowerCase()
isMac = os == 'mac'

log = new MadEye.Logger 'editorState'

class EditorState
  constructor: (@editorId)->
    @_deps = {}
    @editor = new ReactiveAce
    @setupEvents()

  depend: (key) ->
    @_deps[key] ?= new Deps.Dependency
    @_deps[key].depend()

  changed: (key) ->
    @_deps[key]?.changed()

  attach: ->
    @editor.attach @editorId

  setupEvents: ->
    $(window).keydown (event) =>
      if isMac
        usedModifier = event.metaKey
      else
        usedModifier = event.ctrlKey
      return unless usedModifier
      switch String.fromCharCode(event.keyCode)
        when 'S'
          @save()
          event.stopPropagation()
          return false

  getEditor: ->
    @depend 'path'
    @editor.attach @editorId
    newEditor = @editor._getEditor()
    return newEditor

  getFileUrl : (fileId)->
    "#{MadEye.azkabanUrl}/project/#{Projects.findOne(Session.get 'projectId')._id}/file/#{fileId}"

  setCursorDestination: (connectionId)->
    @cursorDestination = connectionId

  setLine: (@lineNumber) ->

  revertFile: (callback=->) ->
    unless @doc and @fileId
      Metrics.add
        level:'warn'
        message:'revertFile with null @doc'
        fileId: @fileId
      console.warn("revert called, but no doc selected")
      return callback? "No doc or no file"
    Events.record("revert", {file: @path, projectId: Session.get "projectId"})
    @working = true
    fileId = @fileId
    #Need to pass version so we know when to add the revert op
    Meteor.call 'revertFile', getProjectId(), fileId, @doc.version, (error, result) =>
      @working = false
      return callback handleNetworkError error if error
      #abort if we've loaded another file
      return callback() unless fileId == @fileId
      if result.warning
        alert = result.warning
        alert.level = 'warn'
        displayAlert alert
      callback()
      #Meteor.setTimeout =>
        #@getEditor().navigateFileStart()
      #,0

    ###
    Meteor.http.get "#{@getFileUrl(@fileId)}?reset=true", (error,response) =>
      @working = false
      if error
        handleNetworkError error, response
        callback?(error)
        return
      #TODO this was in the timeout block below, check to make sure there's no problems
      callback?()
    ###


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
    @doc?.detach_ace?()
    @doc = null
    log.debug "Loading file #{file.path}"
    @loading = true
    finish = (err, doc) =>
      if err
        #TODO: Handle this better.
        log.error "Error in loading file: #{e.message}:", e
      else if doc
        @doc = doc
        @attachAce(doc)
      #else just abort
      @loading = false
      callback? err

    sharejs.open fileId, "text2", "#{MadEye.bolideUrl}/channel", (error, doc) =>
      try
        return finish handleShareError error if error
        #abort if we've loaded another file
        return finish() unless fileId == @fileId
        return finish() unless @checkDocValidity(doc)
        #TODO: @connectionId = doc.connection.id
        if doc.version > 0 or file.scratch
          finish null, doc
        else
          Meteor.call 'requestFile', getProjectId(), fileId, (err, result) =>
            return finish handleNetworkError error if error
            #abort if we've loaded another file
            return finish() unless fileId == @fileId
            if result?.warning
              alert = result.warning
              alert.level = 'warn'
              displayAlert alert
            finish null, doc

      catch e
        finish e

  save : ->
    log.info "Saving file #{@fileId}"
    Events.record("save", {file: @fileId, projectId: Session.get("projectId")})
    editorChecksum = @editor.checksum
    file = Files.findOne @fileId
    return if file.fsChecksum == editorChecksum
    projectId = getProjectId()
    Meteor.call 'saveFile', projectId, @fileId, @editor.value

###
  #callback: (err) ->
  save : (callback) ->
    console.log "Saving file #{@fileId}"
    Events.record("save", {file: @fileId, projectId: Session.get("projectId")})
    Metrics.add message:'saveFile', fileId: @fileId
    editorChecksum = @editor.checksum
    file = Files.findOne @fileId
    return if file.fsChecksum == editorChecksum
    @working = true
    project = getProject()
    Meteor.http.put @getFileUrl(@fileId), {
      data: {contents: @editor.value, static: project.impressJS}
      headers: {'Content-Type':'application/json'}
      timeout: 5*1000
    }, (error,response) =>
      if error
        handleNetworkError error, response
      else
        #XXX: Are we worried about race conditions if there were modifications after the save button was pressed?
        file.update {checksum:editorChecksum}
      @working = false
      project = Projects.findOne Session.get("projectId")
      if project.impressJS
        $("#presentationPreview")[0].contentDocument.location.reload()
        project.lastUpdated = Date.now()
        project.save()
      callback?(error)
###

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
    return unless MadEye.editorState and !MadEye.editorState.loading
    file = Files.findOne(MadEye.editorState.fileId)
    return unless file?.fsChecksum?
    checksum = MadEye.editorState.editor.checksum
    return unless checksum?
    modified = checksum != file.fsChecksum
    file.update {modified}

