# TODO Eliminate need to wrap this in do ->
# https://github.com/meteor/meteor/pull/85

#list of themes and a one liner to try them out one at a time
#themes = ["ace/theme/ambiance", "ace/theme/github", "ace/theme/textmate", "ace/theme/chaos", "ace/theme/idle_fingers", "ace/theme/tomorrow", "ace/theme/chrome", "ace/theme/kr", "ace/theme/tomorrow_night", "ace/theme/clouds", "ace/theme/merbivore", "ace/theme/tomorrow_night_blue", "ace/theme/clouds_midnight", "ace/theme/merbivore_soft", "ace/theme/tomorrow_night_bright", "ace/theme/cobalt", "ace/theme/mono_industrial", "ace/theme/tomorrow_night_eighties", "ace/theme/crimson_editor", "ace/theme/monokai", "ace/theme/twilight", "ace/theme/dawn", "ace/theme/pastel_on_dark", "ace/theme/vibrant_ink", "ace/theme/dreamweaver", "ace/theme/solarized_dark", "ace/theme/xcode", "ace/theme/eclipse", "ace/theme/solarized_light"]
#currentTheme = themes.pop(); ace.edit("editor").setTheme(currentTheme); console.log("current theme is", currentTheme);

handleShareError: (err) ->
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

do ->
  projectIsClosed = ->
    Projects.findOne()?.closed
  
  fileIsDeleted = ->
    Files.findOne(path:editorState.getPath())?.removed

  Handlebars.registerHelper "fileIsDeleted", ->
    fileIsDeleted()

  fileIsModifiedLocally = ->
    Files.findOne(path:editorState.getPath())?.modified_locally

  projectIsLoading = ->
    not (Projects.findOne(Session.get "projectId")? || Session.equals 'fileCount', Files.collection.find().count())

  Template.projectStatus.projectAlerts = ->
    alerts = []
    alerts.push projectClosedError if projectIsClosed()
    alerts.push fileDeletedWarning if fileIsDeleted()
    alerts.push fileModifiedLocallyWarning if fileIsModifiedLocally()
    alerts.push projectLoadingAlert if projectIsLoading()
    alerts.push networkIssuesWarning if transitoryIssues?.has 'networkIssues'
    return alerts

  #Find how many files the server things, so we know if we have them all.
  Meteor.autosubscribe ->
    Meteor.call 'getFileCount', Session.get('projectId'), (err, count)->
      if err
        Metrics.add
          level:'error'
          message:'getFileCount'
        console.error err
        return
      Session.set 'fileCount', count

  Template.editor.preserve("#editor")

  Template.editor.rendered = ->
    Session.set("editorRendered", true)
    resizeEditor()

  Meteor.startup ->
    gotoPosition = (editor, cursor)->
      console.error "udnefined cursor" unless cursor
      position = cursorToRange(editor.getSession().getDocument(), cursor) 
      editorState.getEditor().navigateTo(position.start.row, position.start.column)
      Meteor.setTimeout ->
        editorState.getEditor().scrollToLine(position.start.row, position.start.column)
      , 0

    Meteor.autorun ->
      return unless Session.equals("editorRendered", true)
      filePath = editorState?.getPath()
      return unless filePath?
      file = Files.findOne path:filePath
      return unless file and file._id != editorState.file?._id
      #TODO less hacky way to do this?
      #selectedFilePath?
      Session.set "selectedFileId", file._id
      file.openParents()
      if file.isLink
        displayAlert
          level: "error"
          title: "Unable to load symbolic link"
          message: file.path
        return
      if file.isBinary
        displayAlert
          level: "error"
          title: "Unable to load binary file"
          message: file.path
        return

      editorState.loadFile file, ->
        if editorState.doc.cursors and editorState.cursorDestination
          gotoPosition(editorState.getEditor(), editorState.doc.cursors[editorState.cursorDestination])
        else if editorState.doc.cursor
          gotoPosition(editorState.getEditor(), editorState.doc.cursor)

  Template.editorChrome.events
    'click #revertFile': (event) ->
      Session.set "working", true
      editorState.revertFile (error)->
        Session.set "working", false

    'click #discardFile': (event) ->
      Metrics.add
        message:'discardFile'
        fileId: editorState?.file?._id
        filePath: editorState?.file?.path #don't want reactivity
      editorState.file.remove()
      editorState.file = null
      editorState.setPath ""

    'click #saveImage' : (event) ->
      #console.log "clicked save button"
      Session.set "working", true
      editorState.save (err) ->
        if err
          #Handle error better.
          console.error "Error in save request:", err
        Session.set "working", false

  Handlebars.registerHelper "editorFileName", ->
    editorState?.getPath()

  Handlebars.registerHelper "editorIsLoading", ->
    Session.equals "editorIsLoading", true

  Template.editorChrome.showSaveSpinner = ->
    Session.equals "working", true

  #FIXME: If a connection is re-established, the file is considered modified==false.
  Template.editorChrome.buttonDisabled = ->
    filePath = editorState.getPath()
    file = Files.findOne({path: filePath}) if filePath?
    if !file?.modified or Session.equals("working", true) or projectIsClosed()
      "disabled"
    else
      ""

  resizeEditor = ->
    editorTop = $("#editor").offset().top
    editorLeft = $("#editor").offset().left
    windowHeight = $(window).height()
    windowWidth = $(window).width()
    newHeight = windowHeight - editorTop - 20
    newWidth = windowWidth - editorLeft - 20
    $("#editor").height(newHeight)
    $("#editor").width(newWidth)
    ace.edit("editor").resize()

  Meteor.autorun ->
    return unless Session.equals "editorRendered", true
    $(window).resize ->
      resizeEditor()

