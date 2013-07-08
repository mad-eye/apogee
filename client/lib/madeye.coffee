#Reactive MadEye fields
#If we could define MadEye as a Reactor, this would be cleaner
#console.log "Loading MadEye libs"
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




#Rendered
templates = new ReactiveDict
MadEye.rendered = (template) ->
#  console.log "Marking #{template} as rendered"
  templates.set template, true

MadEye.isRendered = (templs...) ->
#  console.log "Checking if #{templs} is rendered"
#  console.trace()
  return false unless templates.get templ for templ in templs
  return true

