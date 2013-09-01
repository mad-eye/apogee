Meteor.startup ->
  ttyInitialized = false
  Meteor.autorun ->
    return if ttyInitialized
    project = getProject()
    return unless project
    #return if a tty.js session is already active
    if project.tunnels?.terminal
      tunnel = project.tunnels.terminal
      Terminal.ioHost = "share-test.madeye.io"
      Terminal.ioPort = tunnel.remote
      tty.open()
      ttyInitialized = true


onTerminalFocus = ->

onTerminalUnfocus = ->

MadEye.createTerminal = (options) ->
  w = new tty.Window(null, options)
  Meteor.setTimeout ->
    $(".window").click (e) ->
      e.stopPropagation()
  , 0
  $("body").click ->
    tty.Terminal.focus = null
    onTerminalUnfocus()
  return w

