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
@sizes = new ReactiveDict

baseSpacing = 10; #px
inactiveTerminalHeight = 20; #px

terminalWindowPadding = 15 #px
terminalWindowBorder = 2 #2*1px
terminalBorder = 10 #2*5px for #terminal .terminal

Template.editorOverlay.helpers
  spinnerTop: ->
    terminalHeight = sizes.get('terminalHeight') || 0
    editorBottom = terminalHeight + $('#statusBar').height()
    editorHeight = sizes.get('chromeHeight') - editorBottom
    $spinner = $('#editorLoadingSpinner')
    return (editorHeight - $spinner.height())/2

  spinnerLeft: ->
    $spinner = $('#editorLoadingSpinner')
    return (sizes.get('chromeWidth') - $spinner.width())/2

Template.terminalOverlay.helpers
  overlayHeight: ->
    sizes.get('terminalHeight') || 0

  spinnerTop: ->
    terminalHeight = sizes.get('terminalHeight') || 0
    $spinner = $('#terminalBusySpinner')
    # /2.5 gives a more natural feeling position than /2
    return Math.floor (terminalHeight - $spinner.height())/2.5

  spinnerLeft: ->
    $spinner = $('#terminalBusySpinner')
    return Math.floor (sizes.get('chromeWidth') - $spinner.width())/2

Meteor.startup ->
  #Trigger initial size calculations
  windowDep.changed()

  #Set up windowDep listening to window resize
  Deps.autorun (computation) ->
    @name 'setup windowDep'
    return unless MadEye.isRendered 'editor', 'fileTree', 'statusBar'
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
    sizes.set 'chromeHeight', Math.floor $chrome.height()
    sizes.set 'chromeWidth', Math.floor $chrome.width()
    if isTerminalEnabled()
      maxTerminalHeight = Math.floor( $chrome.height() / 3 )
    else
      maxTerminalHeight = 0
    sizes.set 'maxTerminalHeight', maxTerminalHeight

  #Set editor size
  Deps.autorun (c) ->
    @name 'set editor size'
    return unless isEditorPage() and MadEye.isRendered 'editor', 'statusBar'
    return unless $('#statusBar').length and $('#editor').length #XXX: There must be a better way
    terminalHeight = sizes.get('terminalHeight') || 0
    $('#editorContainer').css('bottom', terminalHeight)
    ace.edit('editor').resize()


  #Set terminal size
  Deps.autorun (c) ->
    @name 'set terminalSize'
    return unless isEditorPage()
    unless isTerminalEnabled() and MadEye.isRendered 'terminal'
      sizes.set 'terminalHeight', 0
      return

    terminalHeight = switch
      when not isTerminalOpened()
        inactiveTerminalHeight
      when sizes.get('leastTerminalHeight')
        Math.min sizes.get('leastTerminalHeight'), sizes.get('maxTerminalHeight')
      else
        sizes.get('maxTerminalHeight')

    sizes.set 'terminalHeight', terminalHeight
    $('#terminal').height terminalHeight
    $('#terminalOverlay').height terminalHeight

    if isTerminalOpened()
      unless $('#terminal .window').length
        console.error 'missing terminal window'
        return
      $terminalWindow = $('#terminal .window')
      $terminalWindow.height terminalHeight
      if sizes.get('leastTerminalWidth')
        newWidth = Math.min( sizes.get('leastTerminalWidth'), sizes.get('chromeWidth') )
      else
        newWidth = sizes.get('chromeWidth')
      $terminalWindow.width newWidth

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
    projectStatus = ProjectStatuses.findOne {sessionId:Session.id, projectId}
    return unless projectStatus
    if isTerminalOpened()
      projectStatus.update
        terminalSize:
          height: sizes.get 'maxTerminalHeight'
          width: sizes.get 'chromeWidth'
    else if projectStatus.terminalSize
      #Clear out old terminalSize
      #NB: undefined breaks things!  Also, if you set null when it is already
      #null, it looks 'different' to the collection, and this block becomes
      #an infinite loop.
      projectStatus.update terminalSize: null

  #calculate the minimum height/width of other people's terminals
  Deps.autorun ->
    @name 'calc leastSize'
    return unless isEditorPage()
    projectId = Session.get("projectId")
    return unless projectId
    height = width = null
    
    ProjectStatuses.find({projectId, sessionId: {$ne: Session.id}})
      .forEach (status) ->
        return unless status.terminalSize?
        unless height?
          height = status.terminalSize.height
          width = status.terminalSize.width
        else
          height = Math.min height, status.terminalSize.height
          width = Math.min width, status.terminalSize.width

    sizes.set 'leastTerminalHeight', height
    sizes.set 'leastTerminalWidth', width


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

