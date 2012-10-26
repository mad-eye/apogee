class Router
  constructor: (@routes) -> #@routes is a hash firstPath : routingFn(location)
    Meteor.deps.add_reactive_variable(this, 'page', 'home')

  goto: (location) ->
    location.pathComponents = @stripSlashes(location.pathname).split("/")
    routingFn = @routes[location.pathComponents[0] ? 'missing'] #grab the named function
    routingFn.call(this, location)
    #@page.set(@routing(location))
    
  stripSlashes: (base) ->
    while base.charAt(0) == '/'
      base = base.substr(1)
    while base.charAt(base.length-1) == '/'
      base = base.substring(0,base.length-1)
    return base



router = new Router(
  '' : (location) ->
    this.page.set('home')
  'edit' : (location) ->
    this.page.set('edit')
    if location.pathComponents.length > 1
      Session.set('projectId', location.pathComponents[1])
  'missing' : (location) ->
    this.page.set('missing')

)

Meteor.startup( ->
  router.goto(document.location)
)

