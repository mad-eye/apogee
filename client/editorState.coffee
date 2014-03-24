log = new Logger 'editorState'

#TODO figure out a better way to share this from the ShareJS code
cursorToRange = (editorDoc, cursor) ->
  Range = require("ace/range").Range
  cursor = [cursor, cursor] unless cursor instanceof Array
  start = editorDoc.indexToPosition cursor[0]
  end = editorDoc.indexToPosition cursor[1]
  range = Range.fromPoints start, end
  range.cursor = end
  return range

class @EditorState extends Reactor
  @property 'rendered'
  @property 'fileId'
  @property 'loading' #if a file is loading
  @property 'working' #if a file is saving/reverting
  @property 'connectionId' #shareJs connection Id
  @property 'docName' #shareJs doc name (== fileId)

  constructor: (@editorId)->
    @editor = new ReactiveAce
    @setupEvents()
    #load searchbox module so we can require it later
    @editor.loadModule 'searchbox', (err) ->
      if err
        log.error "Unable to load searchbox script; searching will be harder."
    #load autocomplete/snippets
    @editor.loadModule 'language_tools', (err) =>
      if err
        log.error "Unable to load language tools script; autocomplete won't work."
      else
        log.trace "Enabling autocomplete."
        @editor.enableBasicAutocompletion = true
        @snippetManager = ace.require("ace/snippets")?.snippetManager
    super()

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

  markRendered: ->
    @rendered = true
    @changed 'rendered'

  getEditor: ->
    @editor.attach @editorId
    newEditor = @editor._getEditor()
    return newEditor

  getFileUrl : (fileId)->
    "#{MadEye.azkabanUrl}/project/#{Projects.findOne(Session.get 'projectId')._id}/file/#{fileId}"

  setCursorDestination: (connectionId)->
    @cursorDestination = connectionId

  gotoLine: (lineNumber) ->
    @editor.lineNumber = lineNumber

  checkDocValidity: (doc)->
    unless doc.version?
      #This seems to be a spurious case when the file is opened twice quickly.
      log.error "Found null doc version for file #{@fileId}"
    return doc.version?

  detachShareDoc: ->
    if @doc
      log.trace "Detaching share doc", @doc.name
      @doc.detach_ace?()
      @doc = null

  attachShareDoc: (doc) ->
    fileId = @fileId
    @detachShareDoc()
    unless doc.editorAttached
      log.trace "Attaching share doc", doc.name
      @doc = doc
      @docName = doc.name
      @connectionId = doc.connection.id
      doc.attach_ace @editor._getEditor()
      @editor.newLineMode = "auto"
      doc.on 'warn', (data) =>
        log.warn "ShareJsError", data
      #If we don't have a position, go to the start
      aceEditor = @getEditor()
      if MadEye.fileLoader.lineNumber?
        @gotoLine MadEye.fileLoader.lineNumber
      else if doc.cursor
        position = cursorToRange(aceEditor.getSession().getDocument(), doc.cursor)
        @gotoLine position.start.row
        aceEditor.navigateTo(position.start.row, position.start.column)
        #XXX: Do we need this timeout?
        #Meteor.setTimeout ->
          #aceEditor.scrollToLine(position.start.row, true)
        #, 0
      else
        aceEditor.navigateFileStart()
      doc.emit "cursors"
    else
      log.warn "Editor already attached"

  #This is how many loadFiles we've done.
  #It allows us to bail out of stale callbacks
  loadNumber = 0

  loadFile: (file) ->
    @fileId = fileId = file._id
    finish = (err, doc) =>
      if err
        log.error "Error in loading file:", err
      else if doc
        log.trace "Finished loading; attaching doc for", fileId
        @attachShareDoc doc
        @loading = false
      #else just abort

    if @docName == @fileId
      #When we maximize/minimize the editor, the fileId hasn't changed, but
      #the editor dom elt has been rerendered (and is thus empty).
      #We need to reattach.  Using getEditor is nonreactive.
      if @doc.snapshot != @getEditor().getValue()
        log.trace "Reattaching editor."
        finish null, @doc
      #else it's a duplicate request, do nothing

    else #@docName != @fileId
      #We need to load things the shareJs doc
      @loading = true
      @detachShareDoc()
      log.debug "Loading file #{file.path}"
      Events.record 'loadFile', fileId: fileId, filePath: file.path
      #Know what load we're doing, to bail on stale callbacks
      @currentLoadNumber = thisLoadNumber = loadNumber++

      sharejs.open fileId, "text2", "#{MadEye.bolideUrl}/channel", (error, doc) =>
        try
          log.trace 'Returning from share.js open'
          return finish Errors.wrapShareError error if error
          #abort if we've loaded another file
          return unless thisLoadNumber == @currentLoadNumber
          return unless @checkDocValidity(doc)
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
    Events.record 'saveFile',
      fileId: file._id
      filePath: file.path

    MadEye.featurePromoter.addSkill "saving"

    Meteor.call 'saveFile', projectId, @fileId, @editor.value, (error, result) ->
      return callback Errors.handleError error, log if error
      project = Projects.findOne projectId
      if project.impressJS
        $("#presentationPreview")[0].contentDocument.location.reload()
        #XXX: Should this be a global action on save?
        project.lastUpdated = Date.now()
        project.save()
      callback()
      
  canRevert: ->
    #It's the same logic, for now
    return @canSave()

  revertFile: (callback=->) ->
    unless @doc and @fileId
      log.error "revert called, but no doc selected"
      return callback "No doc or no file"
    return unless @canRevert()
    return unless confirm(
      """Are you sure you want to revert your file?
      This will replace the editor contents with the
      contents of the file on disk.""")
    log.info "Reverting file", @fileId
    Events.record 'revertFile', fileId: @fileId
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

  #Can we discard the file?
  canDiscard: ->
    return false if !getProject() or projectIsClosed()
    fileId = @fileId
    file = Files.findOne(fileId) if fileId?
    return !!file and file.deletedInFs

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

  # Given editorFileId, make sure shareJs doc is loaded
  Meteor.autorun ->
    return unless MadEye.editorState?.rendered
    fileId = MadEye.fileLoader?.editorFileId
    return unless fileId
    file = Files.findOne(fileId)
    return unless file
    MadEye.editorState.loadFile file
