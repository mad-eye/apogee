class ShareJSON
  constructor:(@docId) ->
    @keyDeps = {}
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
      @onReady?()
 
  
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

  _set: (field, value) ->
    data = @doc.get(@connectionId) ? {}
    data[field] = value
    @set(@connectionId, data)

  cleanStaleData: ->
    now = Date.now()
    for cxnId, {heartbeat} of @doc
      delete @doc[cxnId] if now - heartbeat > 10*@heartbeatInterval

  setFilePath: (filePath)->
    @_set('filePath', filePath)

projectStatus = null
Meteor.startup ->
  Meteor.autorun ->
    project = Projects.findOne Session.get "projectId"
    return unless project
    return if projectStatus and projectStatus.docId == project._id
    projectStatus = new ProjectStatus(project._id)
    projectStatus.onReady = ->
      Session.set "projectStatusReady", true
