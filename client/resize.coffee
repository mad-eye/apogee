# All the various resize logic goes here, instead of scattered
# and cluttering up the controllers.
windowDep = new Deps.Dependency()
#the least height/width of other sessions' terminals.
#Store it here to only trigger reactivity if the values change.
@leastSize = new ReactiveDict


baseSpacing = 10; #px
inactiveTerminalHeight = 20; #px

terminalWindowPadding = 15 #px
terminalWindowBorder = 2 #2*1px

@windowSizeChanged = -> windowDep.changed()

Deps.autorun (computation) ->
  return unless MadEye.isRendered 'editor', 'fileTree', 'statusBar'
  windowDep.changed()
  $(window).resize ->
    windowDep.changed()
  computation.stop()


Meteor.startup ->
  windowDep.changed()

  #Editor resize
  Deps.autorun ->
    return unless MadEye.isRendered 'editor', 'statusBar'
    windowDep.depend()
    windowHeight = $(window).height()
    editorContainer = $('#editorContainer')
    editorTop = editorContainer.offset().top

    totalHeight = windowHeight - editorTop - 2*baseSpacing
    editorContainer.height totalHeight
    #Set terminal height to be 1/3rd total
    terminalHeight = Math.floor(totalHeight / 3)
    #If there are other terminals, don't be heigher than them.
    if leastSize.get('height')?
      terminalHeight = Math.min terminalHeight, leastSize.get('height')


    if $('#terminal')
      unless Session.get 'terminalIsActive'
        #Active terminals take up the full space
        #Inactive terminals are just an informational bar (20px)
        terminalHeight = inactiveTerminalHeight
      $('#terminal').height terminalHeight
      terminalWindow = $('#terminal .window')
      if terminalWindow
        terminalWindow.height terminalHeight - terminalWindowPadding - terminalWindowBorder
    else if $('#programOutput')
      $('#programOutput').height terminalHeight
    else
      terminalHeight = 0

    $('#statusBar').css 'bottom', terminalHeight
    $('#editor').css 'bottom', terminalHeight + $('#statusBar').height()

    #Spinner placement
    editorHeight = totalHeight - terminalHeight
    spinner = $('#editorLoadingSpinner')
    spinner.css('top', (editorHeight - spinner.height())/2 )
    spinner.css('left', (editorContainer.width() - spinner.width())/2 )

    ace.edit('editor').resize()

  #Filetree resize
  Deps.autorun ->
    return unless MadEye.isRendered 'fileTree'
    windowDep.depend()
    windowHeight = $(window).height()

    fileTreeContainer = $("#fileTreeContainer")
    fileTreeTop = fileTreeContainer.offset().top
    newFileTreeHeight = Math.min(windowHeight - fileTreeTop - 2*baseSpacing, $("#fileTree").height())
    fileTreeContainer.height(newFileTreeHeight)

  Deps.autorun ->
    projectId = Session.get("projectId")
    return unless projectId
    projectStatus = ProjectStatuses.findOne {sessionId:Session.id, projectId}
    return unless projectStatus
    windowDep.depend()
    if isTerminal() and Session.get 'terminalIsActive'
      terminal = $('#terminal')
      projectStatus.update
        terminalSize:
          height: terminal.height()
          width: terminal.width()
    else
      projectStatus.update terminalSize:undefined

  #calculate the minimum height/width of other people's terminals
  Deps.autorun ->
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

    leastSize.set 'height', height
    leastSize.set 'width', width



