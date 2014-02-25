#Deps to handle resizes.  Might be nice to have reactive DOM elts.
windowDep = new Deps.Dependency()

#
#Store these here to only trigger reactivity if the values change.
##The size of the editorChrome
#chromeHeight
#chromeWidth
#
##the least height/width of other sessions' terminals
#leastTerminalHeight
#leastTerminalWidth
#
##The maximum possible height of terminal (~1/3 chromeHeight)
#maxTerminalHeight
#
##The actual terminal height
#terminalHeight

inactiveTerminalHeight = 20; #px

terminalBorder = 10 #2*5px for #terminal .terminal

class @Resizer extends Reactor
  @property 'chromeHeight'
  @property 'chromeWidth'

  @property 'terminalEnabled'
  @property 'terminalOpened'
  @property 'terminalShown'

  #[{height:, width:}, ...]
  @property 'otherTerminalSizes'
  _minOtherTerminalHeight: ->
    heights = _.pluck @otherTerminalSizes, 'height'
    return null unless heights.length
    return Math.min.apply(null, heights)
  _minOtherTerminalWidth: ->
    widths = _.pluck @otherTerminalSizes, 'width'
    return null unless widths.length
    return Math.min.apply(null, widths)

  @property 'terminalHeight', set:false, get: ->
    switch
      when !@terminalEnabled then 0
      when !@terminalShown then 0
      when !@terminalOpened then inactiveTerminalHeight
      when minHeight = @_minOtherTerminalHeight()
        return Math.min minHeight, @maxTerminalHeight
      else
        @maxTerminalHeight

  @property 'terminalWidth', set:false, get: ->
    switch
      when !@terminalEnabled then 0
      when !@terminalShown then 0
      when !@terminalOpened then @maxTerminalWidth
      when minWidth = @_minOtherTerminalWidth()
        return Math.min minWidth, @maxTerminalWidth
      else
        @maxTerminalWidth

  @property 'maxTerminalHeight', set:false, get: ->
    Math.floor( @chromeHeight / 3 )

  @property 'maxTerminalWidth', set:false, get: ->
    Math.floor( @chromeWidth )

@resizer = new Resizer()

Meteor.startup ->
  #Trigger initial size calculations
  windowDep.changed()

  #Set up windowDep listening to window resize
  Deps.autorun (computation) ->
    @name 'setup windowDep'
    $(window).resize ->
      windowSizeChanged true
    computation.stop()


  Deps.autorun ->
    return unless MadEye.isRendered 'terminal'
    windowDep.depend()



Template.terminalOverlay.helpers
  overlayHeight: ->
    resizer.terminalHeight

  spinnerTop: ->
    $spinner = $('#terminalBusySpinner')
    # /2.5 gives a more natural feeling position than /2
    return Math.floor (resizer.terminalHeight - $spinner.height())/2.5

  spinnerLeft: ->
    $spinner = $('#terminalBusySpinner')
    return Math.floor (resizer.chromeWidth - $spinner.width())/2


Meteor.startup ->

  resizer = {}

  Deps.autorun ->
    @name 'set resizer terminal status'
    resizer.terminalEnabled = MadEye.terminal?.initialized
    resizer.terminalOpened = MadEye.terminal?.opened
    resizer.terminalShown = pageHasTerminal()

  #HACK: Need to poke this explicitly
  @terminalSizeDep = new Deps.Dependency()
  #Set terminal size
  Deps.autorun (c) ->
    @name 'set terminalSize'
    return unless isEditorPage()
    terminalSizeDep.depend()
    $('#terminal').height resizer.terminalHeight
    $('#terminalOverlay').height resizer.terminalHeight

  Deps.autorun ->
    return unless MadEye.terminal?.opened
    unless $('#terminal .window').length
      console.error 'missing terminal window'
      return
    $terminalWindow = $('#terminal .window')
    $terminalWindow.height resizer.terminalHeight
    $terminalWindow.width resizer.terminalWidth

    #Find height of each div
    newTerminalHeight = $terminalWindow.height() - terminalBorder
    newTerminalWidth = $terminalWindow.width() - terminalBorder
    numRows = Math.floor(newTerminalHeight / terminalData.characterHeight)
    numCols = Math.floor(newTerminalWidth / terminalData.characterWidth) - 5
    MadEye.terminal.resize numCols, numRows

      

  #Set projectStatus.terminalSize
  Deps.autorun ->
    @name 'set projectStatus.terminalSize'
    #Want this to run on all pages, so that if someone leaves the editor,
    #their terminalSize is unset.
    projectId = Session.get("projectId")
    return unless projectId
    if resizer.terminalOpened
      terminalSize =
        height: resizer.maxTerminalHeight
        width: resizer.maxTerminalWidth
    else
      #Clear out old terminalSize
      terminalSize = undefined
    Meteor.call "touchProjectStatus", Session.id, projectId, {terminalSize}

  #set other sessions terminal sizes on resizer
  Deps.autorun ->
    @name 'calc leastSize'
    return unless isEditorPage()
    projectId = Session.get("projectId")
    return unless projectId
    
    sizes = ProjectStatuses.find({projectId, sessionId: {$ne: Session.id}}, {fields:{terminalSize:1}})
      .map (status) ->
        status.terminalSize

    sizes = (size for size in sizes when size)
    resizer.otherTerminalSizes = sizes
