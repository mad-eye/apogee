class FileTree
  constructor: ()->
    @openedDirs = new ReactiveDict
    @visibleParents = new ReactiveDict
    @sessionPathsDeps = {}

  getParentPath = (filePath) ->
    return null unless filePath
    filePath.substring 0, filePath.lastIndexOf '/'

  open: (dirPath, withParents=false) ->
    return unless dirPath
    @openedDirs.set dirPath, true
    @open getParentPath(dirPath), true if withParents
    #HACK - this should be some event or reactive variable that a view pays attention to
    Meteor.setTimeout ->
      resizeEditor()
    ,0

  close: (dirPath) ->
    return unless dirPath
    @openedDirs.set dirPath, false
    #HACK - this should be some event or reactive variable that a view pays attention to
    Meteor.setTimeout ->
      resizeEditor()
    ,0

  toggle: (dirPath) ->
    #Don't want the get to be reactive
    if @openedDirs.keys[dirPath]
      @close dirPath
    else
      @open dirPath
    

  isOpen: (dirPath) ->
    @openedDirs.get dirPath

  isVisible: (filePath)->
    parentPath = getParentPath filePath
    return true unless parentPath
    return @isOpen(parentPath) and @isVisible(parentPath)

  select: (file) ->
    return if file._id == @fileId
    @fileId = file._id
    Session.set("selectedFileId", file._id)

  _dependOnSessionPath: (path) ->
    @sessionPathsDeps[path] ?= new Deps.Dependency
    Deps.depend @sessionPathsDeps[path]

  _dependOnSessionPaths: (bottomPath, topPath) ->
    path = bottomPath
    while path
      @_dependOnSessionPath path
      break if path == topPath
      path = getParentPath path

  _invalidatedSessionPaths: (bottomPath, topPath=null) ->
    path = bottomPath
    while path
      @sessionPathsDeps[path]?.changed()
      break if path == topPath
      path = getParentPath path

  _lowestVisiblePath: (filePath) ->
    lowestVisible = filePath
    parentPath = getParentPath filePath
    while parentPath
      lowestVisible = parentPath unless @isOpen parentPath
      parentPath = getParentPath parentPath
    return lowestVisible

  getSessionsInFile: (filePath) ->
    @_dependOnSessionPath filePath
    sessions = []
    for sessionId, path of @sessionPaths
      if filePath == @_lowestVisiblePath path
        #@_dependOnSessionPaths path, filePath
        sessions.push sessionId
    return sessions

  setSessionPaths: (sessionPaths) ->
    oldPaths = _.values @sessionPaths
    newPaths = _.values sessionPaths
    @sessionPaths = _.clone sessionPaths
    _.each oldPaths, (path) =>
      @_invalidatedSessionPaths path
    _.each newPaths, (path) =>
      @_invalidatedSessionPaths path

@FileTree = FileTree
window.fileTree = new FileTree


Deps.autorun ->
  fileId = MadEye.fileLoader?.selectedFileId
  return unless fileId
  file = Files.findOne fileId
  fileTree.select file

