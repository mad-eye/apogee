class @FileLoader extends Reactor
  @property 'loadPath', get:false
  @property 'loadId', get:false

  @property 'selectedFileId', set:false
  @property 'selectedFilePath', set:false
  @property 'editorFileId', set:false
  @property 'editorFilePath', set:false

  @property 'alert'

  @sentry 'loadFile', ->
    loadPath = @_get 'loadPath'
    loadId = @_get 'loadId'
    if loadPath
      file = Files.findOne path:loadPath
    if loadId
      file = Files.findOne loadId unless file
    return unless file
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
        project = getProject()
        return unless project
        type = if project.interview then "interview" else "edit"
        Meteor.Router.to("/#{type}/#{project._id}/#{@editorFilePath}")

MadEye.fileLoader = new FileLoader()

