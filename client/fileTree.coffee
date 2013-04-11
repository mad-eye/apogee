class ReactiveDict
  constructor: () ->
    @deps = {}
    @keys = {}
    
  get: (key) ->
    @deps[key]  ?= new Deps.Dependency
    Deps.depend @deps[key]
    @keys[key]
    
  set: (key, value) ->
    unless @keys[key] == value
      @deps[key]?.changed()
      @keys[key] = value

class ReactiveDictList
  constructor: () ->
    @deps = {}
    @keys = {}

  get: (key) ->
    @deps[key]  ?= new Deps.Dependency
    Deps.depend @deps[key]
    @keys[key] ? []

  add: (key, value) ->
    return unless value?
    @keys[key] ?= []
    return if value in @keys[key]
    @keys[key].push value
    @deps[key]?.changed()

class FileTree
  constructor: ()->
    @openedDirs = new ReactiveDict
    @visibleParents = new ReactiveDict
    @sessionPathsDep = new Deps.Dependency
    
  getParentPath = (filePath) ->
    filePath.substring 0, filePath.lastIndexOf '/'
    
  open: (dirPath, withParents=false) ->
    return unless dirPath
    @openedDirs.set dirPath, true
    @open getParentPath(dirPath), true if withParents
    
  close: (dirPath) ->
    return unless dirPath
    @openedDirs.set dirPath, false
    
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

  lowestVisiblePath: (filePath) ->
    lowestVisible = filePath
    parentPath = getParentPath filePath
    while parentPath
      lowestVisible = parentPath unless @isOpen parentPath
      parentPath = getParentPath parentPath
    return lowestVisible

  select: (file) ->
    console.log "Selecting file", file
    Session.set("selectedFileId", file._id)
    if !file.isDir
      Meteor.Router.to("/edit/#{file.projectId}/#{file.path}")
    else
      @toggle(file.path)

  #TODO: This invalidates for all filePaths; should just invalidate affected paths
  getSessionsInFile: (filePath) ->
    Deps.depend @sessionPathsDep
    sessionsInFile = {}
    for sessionId, path of @sessionPaths
      visiblePath = @lowestVisiblePath path
      sessionsInFile[visiblePath] ?= []
      sessionsInFile[visiblePath].push sessionId

    return sessionsInFile[filePath]

  setSessionPaths: (@sessionPaths) ->
    @sessionPathsDep.changed()

        


