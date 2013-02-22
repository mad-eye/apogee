class ShareJSON
  constructor:(docId) ->
    @keyDeps = {}
    sharejs.open docId, "json", "#{Meteor.settings.public.bolideUrl}/channel", (error, doc) =>
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
