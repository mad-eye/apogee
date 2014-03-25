log = new Logger 'edit'

aceModes = ace.require('ace/ext/modelist')

#TODO NOT SURE ABOUT THIS SECTION.. should everything be in the autorun?
Template.editor.rendered = ->
  Deps.autorun (c) ->
    #Sometimes editorState isn't set up. Attach it when it is.
    return unless MadEye.editorState
    MadEye.editorState.attach()
    #maybe aceAttached?
    MadEye.editorState.markRendered()
    MadEye.rendered 'editor'
    windowSizeChanged()
    c.stop()

Template.edit.helpers
  editorColumnClass: ->
    if Session.get('fileOnly') then 'span12' else 'span9'
    
  showFileTree: ->
    !Session.get('fileOnly')

Template.editorTitleBar.helpers
  editorFileName: ->
    MadEye.fileLoader?.editorFilePath

  isModified: ->
    MadEye.editorState?.canSave()

  isScratch: ->
    fileId = MadEye.editorState?.fileId
    return unless fileId
    return Files.findOne(fileId)?.scratch

Template.editorOverlay.helpers
  editorIsLoading: ->
    MadEye.editorState?.loading

  editorThemeIsDark: MadEye.editorState?.editor.isThemeDark

Template.editorOverlay.rendered = ->

  spinnerOps =
    lines: 11          # The number of lines to draw
    length: 18        # The length of each line
    width: 8          # The line thickness
    radius: 20        # The radius of the inner circle
    corners: 1        # Corner roundness (0..1)
    rotate: 0         # The rotation offset
    direction: 1      # 1: clockwise, -1: counterclockwise
    color: '#000'     # #rgb or #rrggbb or array of colors
    speed: 1          # Rounds per second
    trail: 60         # Afterglow percentage
    shadow: false     # Whether to render a shadow
    hwaccel: false    # Whether to use hardware acceleration
    className: 'spinner' # The CSS class to assign to the spinner
    zIndex: 10000     # The z-index (defaults to 2000000000)
    top: 'auto'       # Top position relative to parent in px
    left: 'auto'      # Left position relative to parent in px

  spinner = new Spinner(spinnerOps).spin(document.getElementById('editorOverlay'))

  
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

