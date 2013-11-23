MEASUREMENT_CHARS = ',./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
log = new Logger 'terminal'

#rows, cols, height, width
@terminalData = {}

setInitialTerminalData = ->
  terminalData.characterHeight = $('#measurementDiv').height()
  terminalData.characterWidth = $('#measurementDiv').width()/MEASUREMENT_CHARS.length
  log.trace "initial terminalData:", terminalData


MadEye.terminal = null
#Initialize terminal connection
Meteor.startup ->
  MadEye.terminal = new METerminal tty

  Meteor.autorun ->
    @name 'initialize terminal'
    return if MadEye.terminal.initialized
    project = getProject()
    return unless project and !project.closed and project.tunnels?.terminal
    #return if a tty.js session is already active
    tunnel = project.tunnels.terminal
    log.trace "Found terminal tunnel:", tunnel
    ioUrl = MadEye.tunnelUrl
    ioResource = "tunnel/#{tunnel.remotePort}/socket.io"
    MadEye.terminal.connect({ioUrl, ioResource})
    MadEye.terminal.on 'focus', onTerminalFocus
    MadEye.terminal.on 'unfocus', onTerminalUnfocus
    MadEye.terminal.on 'reset', minimizeTerminal

Template.terminal.rendered = ->
  MadEye.rendered 'terminal'

onTerminalFocus = ->
  $('#terminal').addClass('focused')

onTerminalUnfocus = ->
  $('#terminal').removeClass('focused')

openTerminal = ->
  log.info "Opening terminal"
  unless MadEye.terminal.window
    parent = $('#terminal')[0]
    MadEye.terminal.create {parent}
    setInitialTerminalData()
    if isReadOnlyTerminal()
      MadEye.terminal.stopBlink()
  else
    $('#terminal .window').show()
  MadEye.terminal.opened = true
  #The div#terminal is constant, so that we don't kill tty's work.
  #Thus we have to hide/show elements
  $('#minimizeTerminalButton').show()
  $('#createTerminalMessage').hide()
  $('#readOnlyTerminalMessage').show()

closeTerminal = ->
  log.info "Closing terminal"
  MadEye.terminal.initialized = false
  #tty.disconnect()
  #MadEye.terminal.destroy()
  #MadEye.terminal = null
  minimizeTerminal()
  
minimizeTerminal = ->
  log.info "Minimizing terminal"
  MadEye.terminal.opened = false
  $('#terminal .window').hide()
  $('#createTerminalMessage').show()
  $('#minimizeTerminalButton').hide()
  $('#readOnlyTerminalMessage').hide()

Template.terminal.events
  'click #createTerminal': (event, tmpl) ->
    event.stopPropagation()
    event.preventDefault()
    openTerminal()

  'click #minimizeTerminalButton': ->
    event.stopPropagation()
    event.preventDefault()
    minimizeTerminal()

Template.terminal.helpers
  measurementChars: -> MEASUREMENT_CHARS

  isTerminalUnavailable: ->
    return getProject()?.tunnels?.terminal?.unavailable

