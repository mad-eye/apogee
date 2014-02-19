# All the various resize logic goes here, instead of scattered
# and cluttering up the controllers.

#Deps to handle resizes.  Might be nice to have reactive DOM elts.
windowDep = new Deps.Dependency()
@windowSizeChanged = (flush) ->
  windowDep.changed()
  Deps.flush() if flush

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

baseSpacing = 10; #px
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

MadEye.resizer = resizer = new Resizer

Template.wholeEditor.helpers
  editorContainerBottom: ->
    Meteor.setTimeout ->
      ace.edit('editor').resize()
    , 1
    resizer.terminalHeight

Template.editorOverlay.helpers
  spinnerTop: ->
    editorBottom = resizer.terminalHeight + $('#statusBar').height()
    editorHeight = resizer.chromeHeight - editorBottom
    $spinner = $('#editorLoadingSpinner')
    return (editorHeight - $spinner.height())/2

  spinnerLeft: ->
    $spinner = $('#editorLoadingSpinner')
    return (resizer.chromeWidth - $spinner.width())/2

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
  #Trigger initial size calculations
  windowDep.changed()

  Deps.autorun ->
    @name 'set resizer terminal status'
    resizer.terminalEnabled = MadEye.terminal?.initialized
    resizer.terminalOpened = MadEye.terminal?.opened
    resizer.terminalShown = pageHasTerminal()

  #Set up windowDep listening to window resize
  Deps.autorun (computation) ->
    @name 'setup windowDep'
    #XXX: Is this necessary?  For terminal/editor only windows, these might not
    #be rendered.
    # Presumably it is cheaper to only do this on pages with the resizer.
    #return unless MadEye.isRendered 'editor', 'fileTree', 'statusBar'
    $(window).resize ->
      windowSizeChanged true
    computation.stop()

  #Set editorChrome size
  Deps.autorun ->
    @name 'set editorChrome size'
    return unless isEditorPage() and MadEye.isRendered 'editor'
    windowDep.depend()
    windowHeight = $(window).height()
    $chrome = $('#editorChrome')
    return unless $chrome and $chrome.offset() #eg home doesn't have this div
    chromeTop = $chrome.offset().top
    chromeHeight = (windowHeight - chromeTop - 2*baseSpacing)
    #Set chrome height here so we know it's complete before we store the values.
    $chrome.height chromeHeight
    resizer.chromeHeight = Math.floor $chrome.height()
    resizer.chromeWidth = Math.floor $chrome.width()

  ###
  #Set editor size
  #Done now in the template.
  Deps.autorun (c) ->
    @name 'set editor size'
    return unless isEditorPage() and MadEye.isRendered 'editor', 'statusBar'
    #return unless $('#statusBar').length and $('#editor').length #XXX: There must be a better way
    $('#editorContainer').css('bottom', resizer.terminalHeight)
    ace.edit('editor').resize()
  ###

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


  #Filetree resize
  Deps.autorun ->
    @name 'filetree resize'
    return unless isEditorPage() and MadEye.isRendered 'fileTree'
    windowDep.depend()
    windowHeight = $(window).height()

    $fileTreeContainer = $("#fileTreeContainer")
    return unless $fileTreeContainer and $fileTreeContainer.offset() #homepage doesn't have filetree
    fileTreeTop = $fileTreeContainer.offset().top
    newFileTreeHeight = Math.min(windowHeight - fileTreeTop - 2*baseSpacing, $("#fileTree").height())
    $fileTreeContainer.height(newFileTreeHeight)

