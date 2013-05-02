# TODO Don't need to wrap this in do-> in Meteor 0.6.0

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

@projectIsClosed = ->
  Projects.findOne()?.closed
  

do ->
  fileIsDeleted = ->
    Files.findOne(path:editorState.getPath())?.removed

  Handlebars.registerHelper "fileIsDeleted", ->
    fileIsDeleted()

  Handlebars.registerHelper "editorFileName", ->
    editorState?.getPath()

  Handlebars.registerHelper "editorIsLoading", ->
    Session.equals "editorIsLoading", true

  Handlebars.registerHelper "isInterview", ->
    Projects.findOne(Session.get "projectId")?.interview

  fileIsModifiedLocally = ->
    Files.findOne(path:editorState.getPath())?.modified_locally

  projectIsLoading = ->
    not (Projects.findOne(Session.get "projectId")? || Session.equals 'fileCount', Files.find().count())

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
    editorState?.isRendered = true
    resizeEditor()

  Meteor.startup ->
    gotoPosition = (editor, cursor)->
      console.error "undefined cursor" unless cursor
      position = cursorToRange(editor.getSession().getDocument(), cursor)
      editorState.getEditor().navigateTo(position.start.row, position.start.column)
      Meteor.setTimeout ->
        editorState.getEditor().scrollToLine(position.start.row, position.start.column)
      , 0

    #TODO: Move this into internal editorState fns
    Meteor.autorun ->
      return unless Session.equals("editorRendered", true)
      filePath = editorState?.getPath()
      return unless filePath?
      file = Files.findOne({path:filePath}) or ScratchPads.findOne({path:filePath})
      return unless file and file._id != editorState.file?._id
      #TODO less hacky way to do this?
      #selectedFilePath?
      Session.set "selectedFileId", file._id
      #no file tree exists for interview page
      fileTree?.open file.path, true
      #Display warning/errors about file state.
      #TODO: Replace this with an overlay.
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
        #XXX hack
        if file instanceof MadEye.ScratchPad and  file.path == "SCRATCH.rb" and editorState.doc.version == 0
          editorState.getEditor().setValue """puts 2+2
          """
        if editorState.doc.cursors and editorState.cursorDestination
          gotoPosition(editorState.getEditor(), editorState.doc.cursors[editorState.cursorDestination])
        else if editorState.doc.cursor
          gotoPosition(editorState.getEditor(), editorState.doc.cursor)


  resizeEditor = ->
    #isInterview = Projects.findOne(Session.get 'projectId')?.interview
    #editorTop = $("#editor").offset().top
    #windowHeight = $(window).height()
    #newHeight = windowHeight - editorTop - 20
    #newHeight = newHeight - 100 if isInterview

    #editorLeft = $("#editor").offset().left
    #windowWidth = $(window).width()
    #newWidth = windowWidth - editorLeft - 20
    #$("#editor").height(newHeight)
    #$("#editor").width(newWidth)
    #ace.edit("editor").resize()

    #$("#programOutput").offset {top: newHeight + 175}


  Meteor.autorun ->
    return unless Session.equals "editorRendered", true
    $(window).resize ->
      resizeEditor()

