###
might be nice to try something more declaritive like this

fileLoader = ReactiveMachine.new {
    properties:
        alert: readWrite
        loadPath: writeOnly
        complicated:
          get: ->
          set: (val) ->

    sentries:
}
###

class @ReactiveMachine
  constructor: (data) ->
    #NB: For some reason, data.sentries is undefined below setting properties.
    #Why, I have no idea.
    @sentries = data.sentries
    @_deps = {}

    for name, data of data.properties
      @addProperty name, data

    self = this
    for sentry in @sentries
      Deps.autorun (computation) ->
        sentry.call self, computation

  depend: (key) ->
    @_deps[key] ?= new Deps.Dependency
    @_deps[key].depend()

  changed: (key) ->
    @_deps[key]?.changed()

  addProperty: (name, data) ->
    descriptor = {}
    getter = data.get
    if 'string' == typeof getter
      varName = getter
      getter = -> return @[varName]
    if getter
      descriptor.get = ->
        @depend name
        return getter.call(this)
    setter = data.set
    if 'string' == typeof setter
      varName = setter
      setter = (value) -> @[varName] = value
    if setter
      descriptor.set = (value) ->
        return if getter and value == getter.call this
        setter.call this, value
        @changed name
    Object.defineProperty this, name, descriptor

@newFileLoader = ->
  new ReactiveMachine
    properties:
      loadPath:
        set: '_loadPath'
      loadId:
        set: '_loadId'
      selectedFileId:
        get: '_selectedFileId'
      selectedFilePath:
        get: '_selectedFilePath'
      editorFileId:
        get: '_editorFileId'
      editorFilePath:
        get: '_editorFilePath'
      alert:
        get: '_alert'
        set: '_alert'
    sentries: [
      (computation) ->
        @depend 'loadId'
        @depend 'loadPath'
        if @_loadPath
          file = Files.findOne path:@_loadPath
        if @_loadId
          file = Files.findOne @_loadId unless file
        return unless file
        @_loadId = @_loadPath = null
        @_selectedFileId = file._id
        @changed 'selectedFileId'
        @_selectedFilePath = file.path
        @changed 'selectedFilePath'

        if file.isDir
          return
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

        #Else, this is a normal file. 
        @_editorFileId = file._id
        @changed 'editorFileId'
        @_editorFilePath = file.path
        @changed 'editorFilePath'
    ]

#MadEye.fileLoader = newFileLoader()

###
class @FileLoader
  constructor: ->
    @_deps = {}
    self = this

    Meteor.autorun (computation) ->
      self._loadFileSentry.call self, computation

  _startSentries: ->
    self = this
    for sentry in sentries
      Meteor.autorun (computation) ->
        sentry.call self, computation

  depend: (key) ->
    @_deps[key] ?= new Deps.Dependency
    @_deps[key].depend()

  changed: (key) ->
    @_deps[key]?.changed()

  _loadFileSentry: (computation) ->
    @depend 'loadId'
    @depend 'loadPath'
    if @_loadPath
      file = Files.findOne path:@_loadPath
    if @_loadId
      file = Files.findOne @_loadId unless file
    return unless file
    @_loadId = @_loadPath = null
    @_selectedFileId = file._id
    @changed 'selectedFileId'
    @_selectedFilePath = file.path
    @changed 'selectedFilePath'

    if file.isDir
      return
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

    #Else, this is a normal file. 
    @_editorFileId = file._id
    @changed 'editorFileId'
    @_editorFilePath = file.path
    @changed 'editorFilePath'


FileLoader.addProperty = (name, getter, setter) ->
  descriptor = {}
  if 'string' == typeof getter
    varName = getter
    getter = -> return @[varName]
  if getter
    descriptor.get = ->
      @depend name
      return getter.call(this)
  if 'string' == typeof setter
    varName = setter
    setter = (value) -> @[varName] = value
  if setter
    descriptor.set = (value) ->
      return if getter and value == getter.call this
      setter.call this, value
      @changed name
  Object.defineProperty FileLoader.prototype, name, descriptor

FileLoader.addProperty 'loadPath', null, '_loadPath'
FileLoader.addProperty 'loadId', null, '_loadId'
FileLoader.addProperty 'selectedFileId', '_selectedFileId'
FileLoader.addProperty 'selectedFilePath', '_selectedFilePath'
FileLoader.addProperty 'editorFileId', '_editorFileId'
FileLoader.addProperty 'editorFilePath', '_editorFilePath'
FileLoader.addProperty 'alert', '_alert', '_alert'
###
