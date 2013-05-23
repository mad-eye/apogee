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
    defaults = write:true, read:true
    options = _.extend defaults, options
    descriptor = {}
    if options.read
      descriptor.get = ->
        @_get name
    else
      descriptor.get = ->
        console.error "Unable to get #{name} [read:false] on", this
        null

    if options.write
      descriptor.set = (value) ->
        return if value == @_get name, false
        @_set name, value
    else
      descriptor.set = (value) ->
        console.error "Unable to set #{name} [write:false] on", this
    Object.defineProperty this.prototype, name, descriptor

