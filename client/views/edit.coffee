log = new Logger 'edit'

aceModes = ace.require('ace/ext/modelist')

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

#XXX: Unused?
Template.editor.preserve("#editor")

#TODO NOT SURE ABOUT THIS SECTION.. should everything be in the autorun?
Template.editor.rendered = ->
  Deps.autorun (c) ->
    #Sometimes editorState isn't set up. Attach it when it is.
    return unless MadEye.editorState
    MadEye.editorState.attach()
    MadEye.editorState.rendered = true
    MadEye.rendered 'editor'
    windowSizeChanged()
    c.stop()

Meteor.startup ->
  gotoPosition = (cursor)->
    unless cursor
      log.error "undefined cursor"
      return
    log.trace 'Going to cursor', cursor
    editor = MadEye.editorState.getEditor()
    position = cursorToRange(editor.getSession().getDocument(), cursor)
    editor.navigateTo(position.start.row, position.start.column)
    Meteor.setTimeout ->
      editor.scrollToLine(position.start.row, true)
    , 0

  #TODO: Move this into internal MadEye.editorState fns
  Deps.autorun ->
    @name 'goto cursor'
    return unless MadEye.isRendered('editor') and MadEye.editorState
    fileId = MadEye.fileLoader?.editorFileId
    return unless fileId?
    file = Files.findOne(fileId)
    return unless file and file._id != MadEye.editorState?.fileId
    MadEye.editorState.loadFile file, (err) ->
      return log.error "Error loading file:", err if err
      return unless fileId == MadEye.editorState.fileId
      log.warn "Editor state finished loading with no doc" unless MadEye.editorState.doc
      if MadEye.editorState.doc?.cursor
        gotoPosition(MadEye.editorState.doc.cursor)

Template.editorOverlay.helpers
  editorIsLoading: ->
    MadEye.editorState?.loading == true

  editorThemeIsDark: MadEye.editorState?.editor.isThemeDark

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

