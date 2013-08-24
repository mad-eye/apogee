#XXXXXX BEGIN EXPERIMENTAL SECTION
invalidatedCallbacks = []

Deps.Computation.prototype.name = (name) ->
  this.onInvalidate ->
    for callback in invalidatedCallbacks
      callback name

#callback : (name) ->
Deps.invalidated = (callback) ->
  invalidatedCallbacks.push callback if callback

#XXXXXX END

#Log when a context has been invalidated.
Deps.invalidated (name) ->
  console.log "Invalidated: #{name}, this:", this

# All the various resize logic goes here, instead of scattered
# and cluttering up the controllers.

#Deps to handle resizes.  Might be nice to have reactive DOM elts.
windowDep = new Deps.Dependency()
@windowSizeChanged = -> windowDep.changed()

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
    spinner = $('#editorLoadingSpinner')
    spinner.css('top', (editorHeight - spinner.height())/2 )

  spinnerLeft: ->
    spinner = $('#editorLoadingSpinner')
    spinner.css('left', (sizes.get('containerWidth') - spinner.width())/2 )

Meteor.startup ->
  #Trigger initial size calculations
  windowDep.changed()

  #Set up windowDep listening to window resize
  Deps.autorun (computation) ->
    @name 'setup windowDep'
    return unless MadEye.isRendered 'editor', 'fileTree', 'statusBar'
    $(window).resize ->
      windowDep.changed()
    computation.stop()

  #Set editorContainer size
  Deps.autorun ->
    @name 'set editorContainer size'
    return unless MadEye.isRendered 'editor'
    windowDep.depend()
    windowHeight = $(window).height()
    container = $('#editorContainer')
    containerTop = container.offset().top
    containerHeight = (windowHeight - containerTop - 2*baseSpacing)
    container.height containerHeight
    sizes.set 'containerHeight', container.height()
    sizes.set 'containerWidth', container.width()
    if isTerminal()
      sizes.set 'maxTerminalHeight', Math.floor( container.height() / 3 )

  #Set editor size
  Deps.autorun (c) ->
    @name 'set editor size'
    return unless MadEye.isRendered 'editor', 'statusBar'
    unless $('#statusBar').length and $('#editor').length
      c.invalidate()
      return
    terminalHeight = sizes.get('terminalHeight') || 0

    #$('#statusBar').css 'bottom', terminalHeight
    editorBottom = terminalHeight + $('#statusBar').height()
    $('#editor').css 'bottom', editorBottom
    ace.edit('editor').resize()

    ##Spinner placement
    #editorHeight = sizes.get('containerHeight') - editorBottom
    #spinner = $('#editorLoadingSpinner')
    #spinner.css('top', (editorHeight - spinner.height())/2 )
    #spinner.css('left', (sizes.get('containerWidth') - spinner.width())/2 )



  #Set terminal size
  Deps.autorun (c) ->
    @name 'set terminalSize'
    return unless isTerminal() and MadEye.isRendered 'terminal'
    terminalHeight = switch
      when not Session.get('terminalIsActive')
        inactiveTerminalHeight
      when sizes.get('leastTerminalHeight')
        Math.min( sizes.get('leastTerminalHeight'), sizes.get('maxTerminalHeight') )
      else
        sizes.get('maxTerminalHeight')

    sizes.set 'terminalHeight', terminalHeight
    unless $('#terminal').length
      console.error 'missing terminal'
    $('#terminal').height terminalHeight

    if Session.get('terminalIsActive')
      unless $('#terminal .window').length
        console.error 'missing terminal window'
        return
      terminalWindow = $('#terminal .window')
      terminalWindow.height terminalHeight - terminalWindowPadding - terminalWindowBorder
      if sizes.get('leastTerminalWidth')
        newWidth = Math.min( sizes.get('leastTerminalWidth'), sizes.get('containerWidth') )
      else
        newWidth = sizes.get('containerWidth')
      terminalWindow.width newWidth

  #Set projectStatus.terminalSize
  Deps.autorun ->
    @name 'set projectStatus.terminalSize'
    projectId = Session.get("projectId")
    return unless projectId
    projectStatus = ProjectStatuses.findOne {sessionId:Session.id, projectId}
    return unless projectStatus
    if isTerminal() and Session.get 'terminalIsActive'
      projectStatus.update
        terminalSize:
          height: sizes.get 'maxTerminalHeight'
          width: sizes.get 'containerWidth'
    else
      projectStatus.update terminalSize:undefined

  #calculate the minimum height/width of other people's terminals
  Deps.autorun ->
    @name 'calc leastSize'
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
    return unless MadEye.isRendered 'fileTree'
    windowDep.depend()
    windowHeight = $(window).height()

    fileTreeContainer = $("#fileTreeContainer")
    fileTreeTop = fileTreeContainer.offset().top
    newFileTreeHeight = Math.min(windowHeight - fileTreeTop - 2*baseSpacing, $("#fileTree").height())
    fileTreeContainer.height(newFileTreeHeight)

