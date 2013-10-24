log = new MadEye.Logger 'depsExtensions'

#EXPERIMENTAL SECTION
invalidatedCallbacks = []

computationsById = {}
computationsByName = {}

Deps.Computation.prototype.name = (name) ->
  this._name = name
  computationsById[this.id] = this
  computationsByName[name] = this

  this.onInvalidate ->
    for callback in invalidatedCallbacks
      callback name

#callback : (name) ->
Deps.invalidated = (callback) ->
  invalidatedCallbacks.push callback if callback


#XXX application specific code
#Log when a context has been invalidated.
#@startDebug = ->
Deps.invalidated (name) ->
  log.trace "Invalidated:", name


#
