log = new Logger 'tty'

class @METerminal
  constructor: (@tty) ->
    MicroEvent.mixin this
    Reactor.mixin this
    Reactor.define this, 'opened'
    Reactor.define this, 'initialized'

  connect: ({@ioUrl, @ioResource}) ->
    log.debug "Opening tty with resource #{@ioResource}"
    @tty.open @ioUrl, @ioResource
    @tty.on 'connect', ->
      log.trace 'Connected'
    @tty.on 'open', ->
      log.trace 'Opened'
    @tty.on 'kill', =>
      log.info 'Received kill signal'
      @reset()
    @initialized = true

  create: ({parent}) ->
    @window = new @tty.Window(null, {parent})
    @window.on 'open', =>
      log.debug "Window opened"
      @refreshTerminalWindow()
      @emit 'focus'
      $(".window").click (e) ->
        #Keep this from triggering the body click event
        e.stopPropagation()

    @window.on 'close', ->
      log.debug 'Window closed'

    @window.on 'focus', =>
      @emit 'focus'

    $("body").click =>
      @_unfocus()

    log.debug "Terminal window created"

  reset: ->
    @tty.reset()
    @window = null
    @initialized = false
    @emit 'reset'
    
  _unfocus: ->
    @tty.Terminal.focus = null
    @emit 'unfocus'

  stopBlink: ->
    @window.focused.stopBlink()

  resize: (numCols, numRows) ->
    @window.resize(numCols, numRows)


  refreshTerminalWindow: ->
    #HACK: Resize causes a redraw of the terminal contents.
    #Trivial resizes don't trigger redraw, and they need to be
    #after the window opens.
    cols = @window.cols
    rows = @window.rows
    @window.resize(cols-1, rows)
    @window.resize(cols, rows)

