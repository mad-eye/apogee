class ShareJSON
  constructor:(@docId) ->
    @keyDeps = {}
    @_readyHandlers = []
    @bigContext = new Meteor.deps._ContextSet()
    sharejs.open @docId, "json", "#{Meteor.settings.public.bolideUrl}/channel", (error, doc) =>
      @connectionId = doc.connection.id
      return handleShareError error if error
      doc.set {} if doc.version == 0
      for key, contextSet of @keyDeps
        contextSet.invalidateAll()
      @bigContext.invalidateAll()
      @doc = doc
      @doc.on "change", (ops)=>
        @listener(ops)
      handler() for handler in @_readyHandlers
      @_readyHandlers = null
      @_ready = true
 
  onReady: (handler) ->
    if @_ready
      handler()
    else
      @_readyHandlers.push handler
  
  listener: (ops)->
    for op in ops
      key = op.p[0]
      @keyDeps[key]?.invalidateAll()
    @bigContext.invalidateAll()

  getAll: ->
    @bigContext.addCurrentContext()
    @doc?.get()
      
  get: (key)->
    contexts = @keyDeps[key] ?= new Meteor.deps._ContextSet()
    contexts.addCurrentContext()
    @doc?.get()[key]

  set: (key, value)->
    #Changes will trigger onChange and the listener will invalidate contexts
    if value != @doc?.get()[key]
      subdoc = @doc.at(key)
      subdoc.set value

  #TODO:  Add equals method, a la Session.equals  

class ProjectStatus extends ShareJSON
  constructor: (@docId) ->
    @heartbeatInterval = 2*1000
    @heartbeatHandle = Meteor.setInterval =>
      try
        @_set 'heartbeat', Date.now()
        @cleanStaleData()
      catch err
        console.error "Heartbeat error:", err.message
    , @heartbeatInterval
    super docId
    @onReady => @_set 'heartbeat', Date.now()

  _set: (field, value) ->
    subdoc = @doc.at(@connectionId)
    subdoc.set {} unless subdoc.get()?
    subdoc.at(field).set value

  cleanStaleData: ->
    now = Date.now()
    for cxnId, data of @doc.get()
      subdoc = @doc.at(cxnId)
      lastHeartbeat = data.heartbeat
      unless lastHeartbeat? and now - lastHeartbeat < 10*@heartbeatInterval
        subdoc.remove()
  
  setFilePath: (filePath) ->
    @_set 'filePath', filePath

  getOpenFiles: ->
    projectData = @getAll()
    fileMap = {}
    for cxnId, data of projectData
      continue unless data.filePath
      fileMap[data.filePath] ?= []
      fileMap[data.filePath].push cxnId
    return fileMap

projectStatus = null
###
Meteor.startup ->
  Meteor.autorun ->
    project = Projects.findOne Session.get "projectId"
    return unless project
    return if projectStatus and projectStatus.docId == project._id
    projectStatus = new ProjectStatus(project._id)
    projectStatus.onReady ->
      Session.set "projectStatusReady", true
###
