'use strict'

class @Reactor
  constructor: ->
    @_keys = {}
    @_deps = {}

  depend: (key) ->
    @_deps[key] ?= new Deps.Dependency
    @_deps[key].depend()

  changed: (key) ->
    @_deps[key]?.changed()

  _get: (key, reactive=true) ->
    @depend name if reactive
    return @_keys[name]

  _set: (key, value, reactive=true) ->
    @_keys[name] = value
    @changed name if reactive

  @property: (name, options) ->
    defaults = get:true, set:true
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

