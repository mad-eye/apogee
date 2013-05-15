###
ReactiveMachine is a class that produces reactiveSingletons.  You can create things like:

widget = ReactiveMachine.new {
  properties:
    foo:
      get: '_foo'
      set: '_foo'
    writeMe:
      set: '_writeMe'
    readMe:
      set: '_readMe'
    complicated:
      get: ->
        #hardcore function
      set: (val) ->
        #more hardcore function

  sentries:
    _convertMe: (computation) ->
      #do something with writeMe, and write to readMe
     
}
###
class @ReactiveMachine
  constructor: (data) ->
    @_deps = {}

    for name, descriptor of data.properties
      @addProperty name, descriptor

    self = this
    sentries = data.sentries

    startSentry = (fixedName, fixedSentry) ->
      self[fixedName] = fixedSentry
      Deps.autorun (computation) ->
        self[fixedName] computation

    for name, sentry of data.sentries
      startSentry name, sentry

  depend: (key) ->
    @_deps[key] ?= new Deps.Dependency
    @_deps[key].depend()

  changed: (key) ->
    @_deps[key]?.changed()

  addProperty: (name, options) ->
    descriptor = {}
    getter = options.get
    if 'string' == typeof getter
      varName = getter
      getter = -> return @[varName]
    if getter
      descriptor.get = ->
        @depend name
        return getter.call(this)
    setter = options.set
    if 'string' == typeof setter
      varName = setter
      setter = (value) -> @[varName] = value
    if setter
      descriptor.set = (value) ->
        return if getter and value == getter.call this
        setter.call this, value
        @changed name
    Object.defineProperty this, name, descriptor


