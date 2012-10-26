class Location
  constructor: (@location) ->
    @pathname = @location.pathname.substring(1)
    @pathComponents = @pathname.split("/")
    @params = @makeParameters(@location.search)
    @hash = @location.hash
    

  #TODO: Only handle single values for keys right now.  Fix!
  makeParameters: (query) ->
    params = {}
    for param in [pair.split("=") for pair in query.split("&")]
      key = param[0]
      value = if param.length > 1 then param[1] else true
      params[key] = value
    return params

class Router
  constructor: (@routing) -> #@routing is a (location) -> 'page'
    Meteor.deps.add_reactive_variable(this, 'page', 'home')

  goto: (location) ->
    @page.set(@routing(location))

router = new Router( (location) ->
  console.log("Going to ", location)
  pathname = location.pathname.substring(1)
  if pathname == ''
    return 'home'
  else if pathname == 'edit'
    return 'edit'
  else
    return 'missing'
)

Meteor.startup( ->
  router.goto(document.location)
)

