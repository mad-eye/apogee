MEASUREMENT_CHARS = ',./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
log = new Logger 'terminal'

#rows, cols, height, width
@terminalData = {}
terminalStatus = new ReactiveDict

setInitialTerminalData = ->
  terminalData.characterHeight = $('#measurementDiv').height()
  terminalData.characterWidth = $('#measurementDiv').width()/MEASUREMENT_CHARS.length
  log.trace "initial terminalData:", terminalData

#Initialize terminal connection
Meteor.startup ->
  Meteor.autorun ->
    return if terminalStatus.get 'ttyInitialized'
    project = getProject()
    return unless project
    #return if a tty.js session is already active
    if project.tunnels?.terminal
      tunnel = project.tunnels.terminal
      log.trace "Found terminal tunnel:", tunnel
      ioUrl = MadEye.tunnelUrl
      ioResource = "tunnel/#{tunnel.remotePort}/socket.io"
      log.trace "Using ioUrl", ioUrl
      tty.Terminal.ioUrl = ioUrl
      tty.Terminal.ioResource = ioResource
      tty.open()
      log.debug "Initialized terminal"
      terminalStatus.set 'ttyInitialized', true

Template.terminal.rendered = ->
  MadEye.rendered 'terminal'

onTerminalFocus = ->
  $('#terminal').addClass('focused')

onTerminalUnfocus = ->
  $('#terminal').removeClass('focused')

@refreshTerminalWindow = (w) ->
  #HACK: Resize causes a redraw of the terminal contents.
  #Trivial resizes don't trigger redraw, and they need to be
  #after the window opens.
  cols = w.cols
  rows = w.rows
  w.resize(cols-1, rows)
  w.resize(cols, rows)

createTerminal = (options) ->
  w = new tty.Window(null, options)
  w.on 'open', =>
    refreshTerminalWindow w
    onTerminalFocus()
    $(".window").click (e) ->
      e.stopPropagation()

  w.on 'focus', onTerminalFocus
  $("body").click ->
    tty.Terminal.focus = null
    onTerminalUnfocus()
  log.debug "Terminal window created"
  return w

closeTerminal = ->
  log.info "Closing terminal"
  MadEye.terminal?.destroy()
  MadEye.terminal = null
  #Must resurrect the createTerminalMessage.
  if $('#createTerminalMessage').length == 0
    frag = Meteor.render(Template.createTerminal)
    $('#terminal').append frag
  terminalStatus.set 'ttyInitialized', false
  tty.disconnect()

Template.terminal.events
  'click #createTerminal': (event, tmpl) ->
    event.stopPropagation()
    event.preventDefault()
    log.info "Opening terminal"
    parent = $('#terminal')[0]
    #The div#terminal is constant, so that we don't kill tty's work.
    #Thus we have to remove the inner contents.
    $('#createTerminalMessage').remove()
    MadEye.terminal = createTerminal parent:parent
    setInitialTerminalData()
    MadEye.terminal.on 'close', closeTerminal

Template.terminal.helpers
  measurementChars: -> MEASUREMENT_CHARS

  isTerminalUnavailable: ->
    return getProject()?.tunnels?.terminal?.unavailable

Meteor.startup ->
  Deps.autorun ->
    Projects.find(Session.get "projectId").observeChanges
      changed: (id, fields) ->
        log.trace "Changes to project:", fields
        if fields.closed
          #This will close the terminal, and recreate the "open terminal" link
          closeTerminal()
        else if 'tunnels' of fields
          #a removed field is in fields as undefined
          if tunnels?.terminal == undefined
            closeTerminal()
          #might be changing unavailable, which will be handled automatically
          #TODO: Handle case where tunnel info (ie, remotePort) is changed
