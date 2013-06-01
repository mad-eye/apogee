'use strict'

class @Reactor
  constructor: ->
    @_keys = {}
    @_deps = {}

    self = this

    startSentry = (fixedName, fixedSentry) ->
      Deps.autorun (computation) ->
        fixedSentry.call self, computation

    for name, sentry of @sentries
      startSentry name, sentry

  depend: (key) ->
    return unless key
    @_deps[key] ?= new Deps.Dependency
    @_deps[key].depend()

  changed: (key) ->
    return unless key
    @_deps[key]?.changed()

  _get: (key, reactive=true) ->
    @depend key if reactive
    return @_keys[key]

  _set: (key, value, reactive=true) ->
    @_keys[key] = value
    @changed key if reactive

  @property: (name, options={}) ->
    defaults = get:true, set:true
    #If we are defining a complex function, default to false for getters/setters.
    defaults.get = false if 'function' == typeof options.set
    defaults.set = false if 'function' == typeof options.get
    options = _.extend defaults, options
    descriptor = {}
    unless options.get
      descriptor.get = ->
        console.error "Unable to get #{name} [read:false] on", this
        null
    else if 'function' == typeof options.get
      descriptor.get = ->
        @depend name
        return options.get.call this
    else
      descriptor.get = ->
        @_get name

    unless options.set
      descriptor.set = (value) ->
        console.error "Unable to set #{name} [write:false] on", this
    else if 'function' == typeof options.set
      descriptor.set = (value) ->
        return if descriptor.get and value == descriptor.get.call this
        options.set.call this, value
        @changed name
    else
      descriptor.set = (value) ->
        return if value == @_get name, false
        @_set name, value
    Object.defineProperty this.prototype, name, descriptor

  @sentry: (name, fn) ->
    @prototype.sentries ?= {}
    @prototype.sentries[name] = fn
