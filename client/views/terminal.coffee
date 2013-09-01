Template.terminal.events
  'click #createTerminal': (event, tmpl) ->
    event.stopPropagation()
    event.preventDefault()
    parent = $('#terminal')[0]
    #The div#terminal is constant, so that we don't kill tty's work.
    #Thus we have to remove the inner contents.
    $('#createTerminalMessage').remove()
    MadEye.terminal = MadEye.createTerminal parent:parent
    setInitialTerminalData()
    MadEye.terminal.on 'close', ->
      console.log "Closing!"
      MadEye.terminal = null
      #Must resurrect the createTerminalMessage.
      frag = Meteor.render(Template.createTerminal)
      $('#terminal').append frag

      

    #HACK: Resize causes a redraw of the terminal contents.
    #Trivial resizes don't trigger redraw, and they need to be
    #after things settle, so need to resize twice a bit after the flush.
    Deps.afterFlush ->
      Meteor.setTimeout ->
        cols = MadEye.terminal.focused.cols
        rows = MadEye.terminal.focused.rows
        console.log "Resising to #{cols} cols #{rows} rows"
        MadEye.terminal.resize(cols-1, rows)
        MadEye.terminal.resize(cols, rows)
      , 100

Template.terminal.rendered = ->
  MadEye.rendered 'terminal'

MEASUREMENT_CHARS = ',./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
Template.terminal.helpers
  measurementChars: -> MEASUREMENT_CHARS

#rows, cols, height, width
@terminalData = {}

setInitialTerminalData = ->
  tab = MadEye.terminal.focused
  terminalData.characterHeight = $('#measurementDiv').height()
  terminalData.characterWidth = $('#measurementDiv').width()/MEASUREMENT_CHARS.length
