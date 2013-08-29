Meteor.startup ->
  ttyInitialized = false
  Meteor.autorun ->
    project = Projects.findOne(Session.get "projectId")
    return unless project
    return if ttyInitialized
    #return if a tty.js session is already active
    if project.tunnels
      for tunnel in project.tunnels
        if tunnel.name == "terminal"
          console.log "START THE TTY.JS SESSION"
          Terminal.ioHost = "share-test.madeye.io"
          Terminal.ioPort = tunnel.remote
          tty.open()
          ttyInitialized = true
