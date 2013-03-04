class TransitoryIssues
  constructor: ()->
    @issues = {}
    @contexts = {}

  set: (type, time) ->
    oldHandle = @issues[type]
    if oldHandle
      clearTimeout oldHandle
    else
      @contexts[type].invalidateAll()
    @issues[type] = Meteor.setTimeout =>
      delete @issues[type]
      @contexts[type].invalidateAll()
    , time


  has: (type) ->
    @contexts[type] ?= new Meteor.deps._ContextSet()
    @contexts[type].addCurrentContext()
    @issues[type]?


