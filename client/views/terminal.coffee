Meteor.startup ->
  #Must reset it, since rerendering destroys the old terminal.
  Session.set 'terminalIsActive', false

Template.terminal.events
  'click #createTerminal': (event, tmpl) ->
    event.stopPropagation()
    event.preventDefault()
    Session.set 'terminalIsActive', true
    #Need to flush to create new div#terminal
    #Deps.flush()
    parent = $('#terminal')[0]
    #HACK: The div#terminal is constant, so that we don't kill tty's work.
    #Thus we have to remove the inner contents.
    $('#createTerminalMessage').remove()
    MadEye.createTerminal parent:parent


Template.terminal.rendered = ->
  MadEye.rendered 'terminal'
