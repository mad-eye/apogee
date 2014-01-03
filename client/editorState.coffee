log = new Logger 'editorState'

class EditorState
  constructor: (@editorId)->
    @_deps = {}
    @editor = new ReactiveAce
    @setupEvents()
    #load searchbox module so we can require it later
    jQuery.getScript("#{Meteor.settings.public.acePrefix}/ext-searchbox.js").fail ->
      log.error "Unable to load searchbox script; searching will be harder."
    #load autocomplete/snippets
    jQuery.getScript("#{Meteor.settings.public.acePrefix}/ext-language_tools.js")
      .fail =>
        log.error "Unable to load language tools script; autocomplete won't work."
      .done =>
        ace.require("ace/ext/language_tools")
        @snippetManager = ace.require("ace/snippets")?.snippetManager

  depend: (key) ->
    @_deps[key] ?= new Deps.Dependency
    @_deps[key].depend()

  changed: (key) ->
    @_deps[key]?.changed()

  attach: ->
    @editor.attach @editorId

  setupEvents: ->
    $(window).keydown (event) =>
      if Client.isMac
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

  gotoLine: (lineNumber) ->
    @editor.lineNumber = lineNumber

  canRevert: ->
    #It's the same logic, for now
    return @canSave()

  revertFile: (callback=->) ->
    unless @doc and @fileId
      Metrics.add
        level:'warn'
        message:'revertFile with null @doc'
        fileId: @fileId
      log.warn "revert called, but no doc selected"
      return callback "No doc or no file"
    return unless @canRevert()
    return unless confirm(
      """Are you sure you want to revert your file?
      This will replace the editor contents with the
      contents of the file on disk.""")
    log.info "Reverting file", @fileId
    Events.record("revert", {file: @path, projectId: Session.get "projectId"})
    @working = true
    fileId = @fileId
    #Need to pass version so we know when to add the revert op
    Meteor.call 'revertFile', getProjectId(), fileId, @doc.version, (error, result) =>
      @working = false
      return callback Errors.handleError error, log if error
      #abort if we've loaded another file
      #XXX: Should we use loadNumber for this check?
      return callback() unless fileId == @fileId
      if result.warning
        alert = result.warning
        alert.level = 'warn'
        displayAlert alert
      Meteor.setTimeout =>
        #give tests a moment more for share to set the editor value
        callback()
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
      log.error "Found null doc version for file #{@fileId}"
    return doc.version?

  detachShareDoc: ->
    if @doc
      log.trace "Detaching share doc", @doc.name
      @doc.detach_ace?()
      @doc = null

  attachShareDoc: (doc)->
    fileId = @fileId
    @detachShareDoc()
    unless doc.editorAttached
      log.trace "Attaching share doc", doc.name
      @doc = doc
      doc.attach_ace @editor._getEditor()
      @editor.newLineMode = "auto"
      doc.on 'warn', (data) =>
        log.warn "ShareJsError", data
        Metrics.add
          level:'warn'
          message:'shareJsError'
          fileId: fileId
          error: data
      #If we don't have a position, go to the start
      @getEditor().navigateFileStart() unless doc.cursor
      doc.emit "cursors"
    else
      Metrics.add
        level:'warn'
        message:'shareJsError'
        fileId: fileId
        error: 'Editor already attached'
      log.warn "Editor already attached"

  #This is how many loadFiles we've done.
  #It allows us to bail out of stale callbacks
  loadNumber = 0

  #callback: (error) ->
  loadFile: (file, callback) ->
    @currentLoadNumber = thisLoadNumber = loadNumber++
    unless file._id
      console.error "Null file._id for file", file
      return callback "LoadFile called with null file._id for #{file.path}"

    @fileId = fileId = file._id
    log.debug "Loading file #{file.path}"
    @loading = true
    @detachShareDoc()
    finish = (err, doc) =>
      if err
        log.error "Error in loading file:", err
      else if thisLoadNumber != @currentLoadNumber
        #abort; do nothing
        0
      else if doc
        log.trace "Finished loading; attaching doc for", file.path
        @attachShareDoc doc
        @loading = false
      #else just abort
      callback? err

    sharejs.open fileId, "text2", "#{MadEye.bolideUrl}/channel", (error, doc) =>
      try
        log.trace 'Returning from share.js open'
        return finish Errors.wrapShareError error if error
        #abort if we've loaded another file
        return finish() unless thisLoadNumber == @currentLoadNumber
        return finish() unless @checkDocValidity(doc)
        @connectionId = doc.connection.id
        if doc.version > 0 or file.scratch
          finish null, doc
        else
          Meteor.call 'requestFile', getProjectId(), fileId, (err, result) =>
            return finish error if error
            #abort if we've loaded another file
            return finish() unless thisLoadNumber == @currentLoadNumber
            if result?.warning
              alert = result.warning
              alert.level = 'warn'
              displayAlert alert
            finish null, doc
      catch e
        finish e

  canSave: ->
    return false if projectIsClosed()
    fileId = @fileId
    file = Files.findOne(fileId) if fileId?
    return false unless file
    return !file.scratch && file.modified

  save : (callback=->) ->
    #TODO: Better error?
    return callback("Can't save") unless @canSave()
    projectId = getProjectId()
    editorChecksum = @editor.checksum
    file = Files.findOne @fileId
    return callback() if file.fsChecksum == editorChecksum
    return callback() if file.scratch
    log.info "Saving file #{file.path}"
    Events.record("save", {file: @fileId, projectId})
    Meteor.call 'saveFile', projectId, @fileId, @editor.value, (error, result) ->
      return callback Errors.handleError error, log if error
      project = Projects.findOne projectId
      if project.impressJS
        $("#presentationPreview")[0].contentDocument.location.reload()
        #XXX: Should this be a global action on save?
        project.lastUpdated = Date.now()
        project.save()
      callback()
      
  #Can we discard the file?
  canDiscard: ->
    return false if !getProject() or projectIsClosed()
    fileId = @fileId
    file = Files.findOne(fileId) if fileId?
    return !!file and file.deletedInFs


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
    if not modified and file.fsChecksum != file.loadChecksum
      #This shouldn't happen -- let's record and consider handling it if it's common.
      log.warn "File is modified on filesystem but not modified in editor; should correct."
