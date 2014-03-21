log = new Logger 'terminal'
MEASUREMENT_CHARS = ',./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'

#rows, cols, height, width
@terminalData = {}

## Terminal helpers

__setInitialTerminalData = ->
  terminalData.characterHeight = $('#measurementDiv').height()
  terminalData.characterWidth = $('#measurementDiv').width()/MEASUREMENT_CHARS.length
  log.trace "initial terminalData:", terminalData

# The project can have a terminal if the client has set one up,
# of a type allowed
__isTerminalEnabled = ->
  #HACK: Make a better page check
  return false unless Router.template == 'terminal'
  project = getProject()
  return false unless project and not project.closed
  terminal = project.tunnels?.terminal
  if terminal?
    if terminal.type == "readOnly"
      return true
    else if terminal.type == "readWrite"
      return Meteor.settings.public.fullTerminal
  return false

__isReadOnlyTerminal = ->
  return getProject()?.tunnels?.terminal.type == "readOnly"

Handlebars.registerHelper "isReadOnlyTerminal", __isReadOnlyTerminal

#terminal should be non-null if this page has a visible terminal
MadEye.terminal = null
#Initialize terminal connection
Meteor.startup ->

  # MadEye.terminal should exist iff the terminal is enabled
  Deps.autorun (c) ->
    return unless __isTerminalEnabled()
    return if MadEye.terminal
    tunnel = getProject().tunnels.terminal
    log.debug "Creating terminal with", tunnel
    Events.record 'initTerminal', type: tunnel.type
    MadEye.terminal = new METerminal tty
    MadEye.terminal.connect
      tunnelUrl: MadEye.tunnelUrl,
      remotePort:tunnel.remotePort
    , ->
      openTerminal()

  Deps.autorun ->
    return unless __isTerminalEnabled()
    tunnel = getProject().tunnels.terminal
    return unless MadEye.terminal?.remotePort != tunnel.remotePort
    log.error "Terminal port switched to #{tunnel.remotePort}, should reconnect"
    #TODO: Shut it down; it should recreate itself

Template.terminal.rendered = ->
  MadEye.rendered 'terminal'

openTerminal = ->
  log.info "Opening terminal"
  Events.record 'openTerminal', type: getProject().tunnels.terminal.type
  parent = $('#terminal')[0]
  MadEye.terminal.create {parent}
  __setInitialTerminalData()
  if __isReadOnlyTerminal()
    MadEye.terminal.stopBlink()

Template.terminal.helpers
  measurementChars: -> MEASUREMENT_CHARS

  isTerminalUnavailable: ->
    return getProject()?.tunnels?.terminal?.unavailable

  isTerminalEnabled: __isTerminalEnabled

Handlebars.registerHelper 'debug', (str) ->
  log.debug str
  return

###
Terminal logic

* MadEye.terminal should exist iff !project.closed and project.tunnels.terminal exists
  * autorun block should change state, initializing or destroying as appropriate
  * needs to check previous state before changing
  * should update tunnel port, which might mean resetting

* #terminal .window should be created when the terminal is opened.
  * it should then be hid/shown as appropriate when opened/closed
  * Moving to non-showing pages (like file) should hide, ready to be reshown.

* When navigating to a page where !pageHasTerminal, close terminal.

###
