class ShareJSON 
  constructor:(docId) ->
    @keyDeps = {}
    settings = Settings.findOne()
    sharejs.open docId, "json", "#{settings.bolideUrl}/channel", (error, doc) =>
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

shareJSON = null

Meteor.startup ->
  Meteor.autorun ->
    return unless Settings.findOne()
    shareJSON = new ShareJSON "hello"

