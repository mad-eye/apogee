aceModes = ace.require('ace/ext/modelist')

@handleShareError = (err) ->
  message = err.message ? err
  Metrics.add
    level:'error'
    message:'shareJsError'
    error: message
  displayAlert { level: 'error', message: message }
  
projectClosedError =
  level: 'error'
  title: 'Project Closed'
  message: 'The project has been closed on the client.'
  uncloseable: true

fileDeletedWarning =
  level: 'warn'
  title: 'File Deleted'
  message: 'The file has been deleted on the client.'
  uncloseable: true

fileDeletedAndModifiedWarning =
  level: 'warn'
  title: 'File Deleted'
  message: 'The file has been deleted on the client.  If you save it, it will be recreated.'
  uncloseable: true

projectLoadingAlert =
  level: 'info'
  title: 'Project is Loading'
  message: "...we'll be ready in a moment!"
  uncloseable: true

fileModifiedLocallyWarning =
  level: 'warn'
  title: 'File Changed'
  message: 'The file has been changed on the client.  Save it to overwrite the changes, or revert to load the changes.'
  uncloseable: true

networkIssuesWarning =
  level: 'warn'
  title: 'Network Issues'
  message: "We're having trouble with the network.  We'll try to resolve it automatically, but you may want to try again later."
  uncloseable: true

cantRunLanguageWarning = (language) ->
  titleLanguage = language ? "unknown"
  messageLanguage = language ? "additional language"
  return {
    level: 'warn'
    title: "Can't run #{titleLanguage}:"
    message: """Currently, we only support running snippets in Ruby, Python, JavaScript, CoffeeScript, and PHP.
      Tell us if you need #{messageLanguage} support, and we'll see what we can do!"""
    uncloseable: true
  }

@canRunLanguage = (language) ->
  language in ["javascript", "python", "ruby", "coffee", "php"]

#TODO figure out a better way to share this from the ShareJS code
cursorToRange = (editorDoc, cursor) ->
  Range = require("ace/range").Range
  cursor = [cursor, cursor] unless cursor instanceof Array
  lines = editorDoc.$lines
  offset = 0
  [start, end] = [null, null]

  for line, i in lines
    if offset + line.length >= cursor[0] and not start
      start = {row:i, column: cursor[0] - offset}
    if offset + line.length >= cursor[1] and not end
      end = {row:i, column: cursor[1] - offset}
    if start and end
      range = new Range()
      #location where the cursor will be drawn
      range.cursor = {row: end.row, column: end.column}
      range.start = start
      range.end = end
      return range
    #+1 for newline
    offset += line.length + 1

fileIsModifiedLocally = ->
  file = Files.findOne MadEye.editorState.fileId
  return false unless file and file.fsChecksum? and file.loadChecksum?
  file.fsChecksum != file.loadChecksum

projectIsLoading = ->
  not MadEye.subscriptions?.get('files')?.ready()

Template.projectStatus.projectAlerts = ->
  alerts = []
  alerts.push projectClosedError if projectIsClosed()
  alerts.push fileDeletedAndModifiedWarning if fileIsDeleted()
  alerts.push fileModifiedLocallyWarning if fileIsModifiedLocally()
  alerts.push projectLoadingAlert if projectIsLoading()
  alerts.push networkIssuesWarning if MadEye.transitoryIssues?.has 'networkIssues'
  alerts.push fileDeletedWarning if MadEye.transitoryIssues?.has 'fileDeleted'
  return alerts

#XXX: Unused?
Template.editor.preserve("#editor")

Template.editor.created = ->
  MadEye.rendered 'editor'
  #Sometimes the resize happens before everything is ready.
  #It's idempotent and cheap, so do this for safety's sake.
  Meteor.setTimeout ->
    resizeEditor()
  , 100

Template.editor.rendered = ->
  #console.log "Rendering editor"
  MadEye.editorState.attach()
  MadEye.editorState.rendered = true
  #If we're displaying the program output, set the bottom of the editor
  outputOffset = if isInterview() then $('#programOutput').height() else 0
  $('#editor').css 'bottom', $('#statusBar').height() + outputOffset
  $('#statusBar').css 'bottom', outputOffset
  resizeEditor()

Meteor.startup ->
  gotoPosition = (cursor)->
    console.error "undefined cursor" unless cursor
    editor = MadEye.editorState.getEditor()
    position = cursorToRange(editor.getSession().getDocument(), cursor)
    editor.navigateTo(position.start.row, position.start.column)
    Meteor.setTimeout ->
      editor.scrollToLine(position.start.row, true)
    , 0

  #TODO: Move this into internal MadEye.editorState fns
  Deps.autorun ->
    return unless MadEye.isRendered 'editor'
    fileId = MadEye.fileLoader?.editorFileId
    return unless fileId?
    file = Files.findOne(fileId)
    return unless file and file._id != MadEye.editorState?.fileId
    MadEye.editorState.loadFile file, ->
      if MadEye.editorState.doc.cursor
        gotoPosition(MadEye.editorState.doc.cursor)

@resizeEditor = ->
  baseSpacing = 10; #px
  windowHeight = $(window).height()

  editorContainer = $('#editorContainer')
  editorContainerOffset = editorContainer?.offset()
  if editorContainerOffset
    editorTop = editorContainerOffset.top
    newHeight = windowHeight - editorTop - 2*baseSpacing
    editorContainer.height(newHeight)

    #Spinner placement
    spinner = $('#editorLoadingSpinner')
    spinner.css('top', (newHeight - spinner.height())/2 )
    spinner.css('left', (editorContainer.width() - spinner.width())/2 )

    ace.edit('editor').resize()

  fileTreeContainer = $("#fileTreeContainer")
  fileTreeContainerOffset = fileTreeContainer?.offset()
  if fileTreeContainerOffset
    fileTreeTop = fileTreeContainerOffset.top
    newFileTreeHeight = Math.min(windowHeight - fileTreeTop - 2*baseSpacing, $("#fileTree").height())
    fileTreeContainer.height(newFileTreeHeight)

Deps.autorun (computation) ->
  return unless MadEye.isRendered 'editor', 'fileTree', 'statusBar'
  resizeEditor()
  $(window).resize ->
    resizeEditor()
  computation.stop()

Template.editorOverlay.helpers
  "editorIsLoading": ->
    MadEye.editorState.loading == true

Template.editorFooter.helpers
  output: ->
    outputs = ScriptOutputs.find {projectId: Session.get("projectId")}, {sort: {timestamp: -1}}
    output = ""
    if Session.get "codeExecuting"
      output += """<div id="codeExecutingSpinner"><img src="/images/file-loader.gif" alt="Loading..." /></div>\n"""
    unless outputs.count()
      output += """<span class="initial-output">program output will go here</span>\n"""
    else
      outputs.forEach (response)->
        if 0 == response.exitCode
          responseClass = "faded"
          responseMessage = "#{response.filename} returned:"
        else
          responseClass = "output-error"
          responseMessage = "#{response.filename} returned error (#{response.exitCode}):"
        output += """<span class="#{responseClass}">#{responseMessage}</span>\n"""
        output += """<span class="stdout">#{response.stdout}</span>\n""" if response.stdout
        
        output += """<span class="stderr">#{response.stderr}</span>\n""" if response.stderr
        output += """<span class="runError">#{response.runError}</span>\n""" if response.runError
    output

Template.editImpressJS.helpers
  projectId: ->
    Session.get("projectId")

Template.fileUpload.rendered = ->
  return if Dropzone.forElement "#dropzone"
  $("#dropzone").dropzone
    paramName: "file"
    accept: (dropfile, done)->
      file = new MadEye.File
      file.scratch = true
      file.path = dropfile.name
      file.projectId = Session.get "projectId"
      try
        file.save()
        @options.url = "#{MadEye.azkabanUrl}/file-upload/#{file._id}"
        done()
      catch e
        alert e.message
        done(e.message)
    url: "bogus" #can't initialize a dropzone w/o a url, overwritten in accept function above

