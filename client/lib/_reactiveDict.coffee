class @ReactiveDict
  constructor: () ->
    @deps = {}
    @keys = {}

  get: (key) ->
    @deps[key]  ?= new Deps.Dependency
    Deps.depend @deps[key]
    @keys[key]

  set: (key, value) ->
    unless @keys[key] == value
      @deps[key]?.changed()
      @keys[key] = value


