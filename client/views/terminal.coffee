MEASUREMENT_CHARS = ',./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
#
#rows, cols, height, width
@terminalData = {}

setInitialTerminalData = ->
  terminalData.characterHeight = $('#measurementDiv').height()
  terminalData.characterWidth = $('#measurementDiv').width()/MEASUREMENT_CHARS.length

#Initialize terminal connection
Meteor.startup ->
  ttyInitialized = false
  Meteor.autorun ->
    return if ttyInitialized
    project = getProject()
    return unless project
    #return if a tty.js session is already active
    if project.tunnels?.terminal
      tunnel = project.tunnels.terminal
      Terminal.ioHost = Meteor.settings.public.shareSever
      Terminal.ioPort = tunnel.remote
      tty.open()
      ttyInitialized = true

Template.terminal.rendered = ->
  MadEye.rendered 'terminal'

onTerminalFocus = ->

onTerminalUnfocus = ->

createTerminal = (options) ->
  w = new tty.Window(null, options)
  w.on 'open', =>
    #HACK: Resize causes a redraw of the terminal contents.
    #Trivial resizes don't trigger redraw, and they need to be
    #after the window opens.
    cols = w.cols
    rows = w.rows
    w.resize(cols-1, rows)
    w.resize(cols, rows)

    $(".window").click (e) ->
      e.stopPropagation()

  $("body").click ->
    tty.Terminal.focus = null
    onTerminalUnfocus()
  return w

Template.terminal.events
  'click #createTerminal': (event, tmpl) ->
    event.stopPropagation()
    event.preventDefault()
    parent = $('#terminal')[0]
    #The div#terminal is constant, so that we don't kill tty's work.
    #Thus we have to remove the inner contents.
    $('#createTerminalMessage').remove()
    MadEye.terminal = createTerminal parent:parent
    setInitialTerminalData()
    MadEye.terminal.on 'close', ->
      console.log "Closing!"
      MadEye.terminal = null
      #Must resurrect the createTerminalMessage.
      frag = Meteor.render(Template.createTerminal)
      $('#terminal').append frag

Template.terminal.helpers
  measurementChars: -> MEASUREMENT_CHARS

