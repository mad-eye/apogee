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
