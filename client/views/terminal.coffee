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
