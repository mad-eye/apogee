class ShareJSON
  constructor:(@docId) ->
    @keyDeps = {}
    sharejs.open @docId, "json", "#{Meteor.settings.public.bolideUrl}/channel", (error, doc) =>
      @connectionId = doc.connection.id
      return handleShareError error if error
      doc.set {} if doc.version == 0
      @doc = doc
      @doc.on "change", (ops)=>
        @listener(ops)
  
  listener: (ops)->
    for op in ops
      key = op.p[0]
      @keyDeps[key]?.invalidateAll()

  get: (key)->
    contexts = @keyDeps[key] ?= new Meteor.deps._ContextSet()
    contexts.addCurrentContext()
    @doc.get()[key]

  set: (key, value)->
    if value != @doc.get()[key]
      subdoc = @doc.at(key)
      subdoc.set value

  #TODO:  Add equals method, a la Session.equals  


class Cursors extends ShareJSON

cursorPositions = null
Meteor.startup ->
  Meteor.autorun ->
    project = Projects.findOne()
    return unless project
    return if cursorPositions and cursorPositions.docId == project._id
    cursorPositions = new ShareJSON(project._id)
