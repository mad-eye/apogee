Template.terminal.events
  'click #createTerminal': (event, tmpl) ->
    event.stopPropagation()
    event.preventDefault()
    parent = $('#terminal')[0]
    #HACK: The div#terminal is constant, so that we don't kill tty's work.
    #Thus we have to remove the inner contents.
    $('#createTerminalMessage').remove()
    MadEye.terminal = MadEye.createTerminal parent:parent
    setInitialTerminalData()
    #HACK: Resize causes a redraw of the terminal contents.
    #Trivial resizes don't trigger redraw, and they need to be
    #after things settle, so need to resize twice a bit after the flush.
    Deps.afterFlush ->
      Meteor.setTimeout ->
        cols = MadEye.terminal.focused.cols
        rows = MadEye.terminal.focused.rows
        MadEye.terminal.resize(cols-1, rows)
        MadEye.terminal.resize(cols, rows)
      , 100

Template.terminal.rendered = ->
  MadEye.rendered 'terminal'

#rows, cols, height, width
@initialTerminalData = {}

setInitialTerminalData = ->
  tab = MadEye.terminal.focused
  initialTerminalData.cols = tab.cols
  initialTerminalData.rows = tab.rows
  initialTerminalData.height = $('#terminal .terminal').height()
  initialTerminalData.width = $('#terminal .terminal').width()
