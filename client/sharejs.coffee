class ShareJSON 
  constructor: ->
    @contexts = new Meteor.deps._ContextSet()
  
  get: ->
    @contexts.addCurrentContext()
    @value

  set: (value)->
    if value != @value
      @value = value
      @contexts.invalidateAll()

shareJSON = new ShareJSON
shareJSON.set "yoyoyo"

Meteor.autorun ->
  console.log shareJSON.get()
