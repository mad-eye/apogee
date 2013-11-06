#Reactive MadEye fields
#If we could define MadEye as a Reactor, this would be cleaner
deps = {}
keys = {}

addMadEyeProperty= (name) ->
  Object.defineProperty MadEye, name,
    get: ->
      deps[name] ?= new Deps.Dependency
      deps[name].depend()
      keys[name]
    set: (value) ->
      return if keys[name] == value
      keys[name] = value
      deps[name]?.changed()
      
addMadEyeProperty 'editorState'
addMadEyeProperty 'fileTree'
addMadEyeProperty 'fileLoader'
addMadEyeProperty 'transitoryIssues'
addMadEyeProperty 'startedUp'
addMadEyeProperty 'terminal'
addMadEyeProperty 'subscriptions'




#Rendered
templates = new ReactiveDict
MadEye.rendered = (template) ->
  #console.log "Marking #{template} as rendered"
  templates.set template, true

MadEye.isRendered = (templs...) ->
  #console.log "Checking if #{templs} is rendered"
  for templ in templs
    return false unless templates.get templ
  return true

