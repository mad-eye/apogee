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
  project = getProject()
  return false unless project and not project.closed
  terminal = project.tunnels?.terminal
  if terminal?
    if terminal.type == "readOnly"
      return true
    else if terminal.type == "readWrite"
      return Meteor.settings.public.fullTerminal
  return false

# Some pages don't show a terminal
# Needed for resizer
@pageHasTerminal = ->
  Router.template in ['edit']

__isReadOnlyTerminal = ->
  return getProject()?.tunnels.terminal.type == "readOnly"

Handlebars.registerHelper "showTerminal", ->
  return __isTerminalEnabled() && pageHasTerminal()

Handlebars.registerHelper "isReadOnlyTerminal", __isReadOnlyTerminal

MadEye.terminal = null
#Initialize terminal connection
Meteor.startup ->

  # MadEye.terminal should exist iff the terminal is enabled
  Deps.autorun (c) ->
    @name 'enable terminal'
    if __isTerminalEnabled()
      #No need to do anything (but possibly close the terminal) if we are on
      #another page
      if !pageHasTerminal()
        minimizeTerminal()
        return
      #create a terminal if it doesn't exist. This might mean initializing it
      tunnel = getProject().tunnels.terminal
      unless MadEye.terminal
        log.debug "Creating terminal with", tunnel
        Events.record 'initTerminal', type: tunnel.type
        MadEye.terminal = new METerminal tty
        MadEye.terminal.connect({tunnelUrl: MadEye.tunnelUrl, remotePort:tunnel.remotePort})
        MadEye.terminal.on 'focus', onTerminalFocus
        MadEye.terminal.on 'unfocus', onTerminalUnfocus
        #XXX: This is stateful, and possibly causing some of our issues.
        #MadEye.terminal.on 'reset', minimizeTerminal
      else if MadEye.terminal.remotePort != tunnel.remotePort
        #TODO: check for port change
        log.info "Terminal port switched to #{tunnel.remotePort}, reconnecting"
        #Shut it down; it should recreate itself
        MadEye.terminal.shutdown()
        MadEye.terminal = null
    else
      if MadEye.terminal
        #Can't support it; get rid of it
        MadEye.terminal.shutdown()
        MadEye.terminal = null


  Deps.autorun ->
    @name 'initialize terminal'
    return unless MadEye.terminal and not MadEye.terminal.initialized
    project = getProject()
    return unless project and not project.closed
    #As a sanity check, let's log an error if we don't have terminal data
    unless project.tunnels?.terminal
      log.error "Project has enabled terminal, but no terminal data:", project
      return
    #return if a tty.js session is already active
    tunnel = project.tunnels.terminal

Template.terminal.rendered = ->
  MadEye.rendered 'terminal'

onTerminalFocus = ->
  $('#terminal').addClass('focused')

onTerminalUnfocus = ->
  $('#terminal').removeClass('focused')

openTerminal = ->
  log.info "Opening terminal"
  Events.record 'openTerminal', type: getProject().tunnels.terminal.type
  unless MadEye.terminal.window
    parent = $('#terminal')[0]
    MadEye.terminal.create {parent}
    __setInitialTerminalData()
    if __isReadOnlyTerminal()
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

###
Meteor.startup ->
  #XXX: This is stateful, and possibly causing some of our issues.
  Deps.autorun ->
    Projects.find(Session.get('projectId'), {fields:{tunnels:1}}).observeChanges
      changed: (id, fields) ->
        log.trace "Observed project change:", fields
        #Removing a field is signified by field:undefined
        return unless 'tunnels' of fields
        tunnels = fields.tunnels
        if !tunnels
          #tunnels was removed, possibly because the project was closed
          log.debug "Terminal tunnel closed; resetting."
          MadEye.terminal.reset()
        else if tunnels.terminal?.remotePort?
          #Changed remote port; reset the terminal and it'll reconnect automatically
          log.debug "Terminal tunnel changed ports; resetting."
          MadEye.terminal.reset()
###

Handlebars.registerHelper 'debug', (str) ->
  log.debug str
  return

Template.wholeEditor.rendered = ->
  #HACK: Need to poke the autoruns after it's rendered.
  #Should be unnecessary when blaze lands.
  terminalSizeDep?.changed()

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
