Handlebars.registerHelper "Settings", ->
  Settings.findOne()

Handlebars.registerHelper "session", (key) ->
  Session.get key

Handlebars.registerHelper "sessionEquals", (key, value) ->
  Session.equals key, value
