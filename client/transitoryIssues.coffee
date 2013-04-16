class TransitoryIssues
  constructor: ()->
    @issues = {}
    @deps = {}

  set: (type, time) ->
    oldHandle = @issues[type]
    if oldHandle
      clearTimeout oldHandle
    else
      @deps[type]?.changed()
    @issues[type] = Meteor.setTimeout =>
      delete @issues[type]
      @deps[type]?.changed()
    , time


  has: (type) ->
    @deps[type] ?= new Deps.Dependency
    Deps.depend @deps[type]
    @issues[type]?

@TransitoryIssues = TransitoryIssues
