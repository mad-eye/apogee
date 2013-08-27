# All the various resize logic goes here, instead of scattered
# and cluttering up the controllers.

#Deps to handle resizes.  Might be nice to have reactive DOM elts.
windowDep = new Deps.Dependency()
@windowSizeChanged = (flush) ->
  windowDep.changed()
  if flush
    Deps.flush()


#Store these here to only trigger reactivity if the values change.
##The size of the editorContainer
#containerHeight
#containerWidth
#
##the least height/width of other sessions' terminals
#leastTerminalHeight
#leastTerminalWidth
#
##The maximum possible height of terminal (~1/3 containerHeight)
#maxTerminalHeight
#
##The actual terminal height
#terminalHeight
@sizes = new ReactiveDict

baseSpacing = 10; #px
inactiveTerminalHeight = 20; #px

terminalWindowPadding = 15 #px
terminalWindowBorder = 2 #2*1px

Template.statusBar.helpers
  bottom: -> sizes.get('terminalHeight') || 0

Template.editorOverlay.helpers
  spinnerTop: ->
    terminalHeight = sizes.get('terminalHeight') || 0
    editorBottom = terminalHeight + $('#statusBar').height()
    editorHeight = sizes.get('containerHeight') - editorBottom
    $spinner = $('#editorLoadingSpinner')
    $spinner.css('top', (editorHeight - $spinner.height())/2 )

  spinnerLeft: ->
    $spinner = $('#editorLoadingSpinner')
    $spinner.css('left', (sizes.get('containerWidth') - $spinner.width())/2 )

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

  #Set editorContainer size
  Deps.autorun ->
    @name 'set editorContainer size'
    return unless isEditorPage() and MadEye.isRendered 'editor'
    windowDep.depend()
    windowHeight = $(window).height()
    $container = $('#editorContainer')
    return unless $container and $container.offset() #eg home doesn't have this div
    containerTop = $container.offset().top
    containerHeight = (windowHeight - containerTop - 2*baseSpacing)
    #Set container height here so we know it's complete before we store the values.
    $container.height containerHeight
    sizes.set 'containerHeight', Math.floor $container.height()
    sizes.set 'containerWidth', Math.floor $container.width()
    if isTerminal()
      sizes.set 'maxTerminalHeight', Math.floor( $container.height() / 3 )

  #Set editor size
  Deps.autorun (c) ->
    @name 'set editor size'
    return unless isEditorPage() and MadEye.isRendered 'editor', 'statusBar'
    return unless $('#statusBar').length and $('#editor').length #XXX: There must be a batter way
    terminalHeight = sizes.get('terminalHeight') || 0

    #$('#statusBar').css 'bottom', terminalHeight
    editorBottom = terminalHeight + $('#statusBar').height()
    $('#editor').css 'bottom', editorBottom
    ace.edit('editor').resize()


  #Set terminal size
  Deps.autorun (c) ->
    @name 'set terminalSize'
    return unless isEditorPage() and isTerminal() and MadEye.isRendered 'terminal'
    terminalHeight = switch
      when not MadEye.terminal
        inactiveTerminalHeight
      when sizes.get('leastTerminalHeight')
        Math.min( sizes.get('leastTerminalHeight'), sizes.get('maxTerminalHeight') )
      else
        sizes.get('maxTerminalHeight')

    sizes.set 'terminalHeight', terminalHeight
    $('#terminal').height terminalHeight

    if MadEye.terminal
      unless $('#terminal .window').length
        console.error 'missing terminal window'
        return
      $terminalWindow = $('#terminal .window')
      terminalWindowHeight = terminalHeight - terminalWindowPadding - terminalWindowBorder
      $terminalWindow.height terminalWindowHeight
      if sizes.get('leastTerminalWidth')
        newWidth = Math.min( sizes.get('leastTerminalWidth'), sizes.get('containerWidth') )
      else
        newWidth = sizes.get('containerWidth')
      $terminalWindow.width newWidth - terminalWindowBorder

      #Find height of each div
      newTerminalHeight = $terminalWindow.height() #FIXME Must reduce by size of bar/etc
      newTerminalWidth = $terminalWindow.width() #FIXME Must reduce by size of border/etc
      numRows = Math.floor (newTerminalHeight / initialTerminalData.height) * initialTerminalData.rows
      numCols = Math.floor (newTerminalWidth / initialTerminalData.width) * initialTerminalData.cols
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
    if MadEye.terminal
      projectStatus.update
        terminalSize:
          height: sizes.get 'maxTerminalHeight'
          width: sizes.get 'containerWidth'
    else
      projectStatus.update terminalSize: null #NB: undefined breaks things!

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

