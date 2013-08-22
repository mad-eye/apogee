Meteor.startup ->
  #Must reset it, since rerendering destroys the old terminal.
  Session.set 'terminalIsActive', false

Template.editorFooter.events
  'click #createTerminal': (event, tmpl) ->
    event.stopPropagation()
    event.preventDefault()
    Session.set 'terminalIsActive', true
    #Need to flush to create new div#terminal
    Deps.flush()
    parent = $('#terminal')[0]
    MadEye.createTerminal parent:parent
    windowSizeChanged()


