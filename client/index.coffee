Handlebars.registerHelper('currentPage', ->
  return router?.page()
)

Handlebars.registerHelper('render', (name) ->
  return Template[name]() if Template[name]
)

Template.navbar.account = ->
  return Session.get("user")

Template.navbar.events(
  'click #logoutButton' : (event) ->
    event.preventDefault()
    event.stopPropagation()
    Session.set('user', null)
)

Template.signinModal.events(
  'click #signInButton' : (event) ->
    event.preventDefault()
    event.stopPropagation()
    $('#myModal').modal('hide')
    #TODO: Sign in to github.
    paramArray = $('#signInForm').serializeArray()
    username = null
    for field in paramArray
      if (field['name'] == 'username')
        username = field['value']
        break
    if username
      console.log("Found username " + username)
      Session.set("user", username)
)


