log = new MadEye.Logger 'fileLoader'

class @FileLoader extends Reactor
  @property 'loadPath', get:false
  @property 'loadId', get:false

  @property 'selectedFileId', set:false
  @property 'selectedFilePath', set:false
  @property 'editorFileId', set:false
  @property 'editorFilePath', set:false

  @property 'alert'

  clearFile: ->
    log.trace 'Clearing file'
    @_set 'selectedFileId',  null
    @_set 'selectedFilePath',  null
    @_set 'editorFileId',  null
    @_set 'editorFilePath',  null
    @_route()

  _route: ->
    project = getProject()
    return unless project
    if project.impressJS
      type = "editImpressJS"
    else
      type = "edit"
    #filePath = encodeURIComponent( @editorFilePath ? "" ).replace(/%2F/g, '/')
    ## ironRouter automatically escapes our params.  This means, unfortunately,
    ## that it escapes our slashes.  We can fix this pending resolution to
    ## https://github.com/EventedMind/iron-router/issues/198
    filePath = @editorFilePath
    #log.trace "Loading #{filePath}"
    Router.go type, projectId: project._id, filePath: filePath

  @sentry 'loadFile', ->
    loadPath = @_get 'loadPath'
    loadId = @_get 'loadId'
    if loadPath
      file = Files.findOne path:loadPath
    if loadId
      file = Files.findOne loadId unless file
    return unless file
    log.trace "Found load file #{file.path}"
    @_set 'loadId', null, false
    @_set 'loadPath', null, false
    unless @_get('selectedFileId', false) == file._id
      @_set 'selectedFileId', file._id
      @_set 'selectedFilePath', file.path

    if file.isLink
      @alert =
        level: "error"
        title: "Unable to load symbolic link"
        message: file.path
      return
    if file.isBinary
      @alert =
        level: "error"
        title: "Unable to load binary file"
        message: file.path
      return

    @alert = null
    return if file.isDir

    #Else, this is a normal file. 
    unless @_get('editorFileId', false) == file._id
      @_set 'editorFileId', file._id
      @_set 'editorFilePath', file.path

  @sentry 'route', ->
    return unless @editorFilePath
    @_route()
