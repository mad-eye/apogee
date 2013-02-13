class ShareJSON 
  constructor:(docId) ->
#    @keyDeps = new Meteor.deps._ContextSet()
    settings = Settings.findOne()
    sharejs.open docId, "json", "#{settings.bolideUrl}/channel", (error, doc) =>
      @doc = doc
  #      @doc.onChildOp @listener
  
  listener: ()->

  get: (key)->
#    @keyDeps.addCurrentContext()
    @doc.get()[key]

  set: (key, value)->
    if value != @doc.get()[key]
      subdoc = @doc.at(key)
      subdoc.set value
#      @contexts.invalidateAll()

Meteor.startup ->
  return unless Settings.findOne()
  shareJSON = new ShareJSON "hello"
  shareJSON.set "yoyoyo", "fascinating"

  Meteor.autorun ->
    console.log shareJSON.get("yoyoyo")
