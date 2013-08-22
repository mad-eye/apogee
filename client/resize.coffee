# All the various resize logic goes here, instead of scattered
# and cluttering up the controllers.
windowDep = new Deps.Dependency()
baseSpacing = 10; #px

@windowSizeChanged = -> windowDep.changed()

Deps.autorun (computation) ->
  return unless MadEye.isRendered 'editor', 'fileTree', 'statusBar'
  windowDep.changed()
  $(window).resize ->
    windowDep.changed()
  computation.stop()


#Editor resize
Meteor.startup ->
  Deps.autorun ->
    return unless MadEye.isRendered 'editor', 'statusBar'
    windowDep.depend()
    windowHeight = $(window).height()
    editorContainer = $('#editorContainer')
    editorTop = editorContainer.offset().top

    totalHeight = windowHeight - editorTop - 2*baseSpacing
    editorContainer.height totalHeight

    if $('#terminal')
      offset = $('#terminal').height()
    else if $('#programOutput')
      offset = $('#programOutput').height()
    else
      offset = 0
    $('#statusBar').css 'bottom', offset
    $('#editor').css 'bottom', offset + $('#statusBar').height()

    #Spinner placement
    newHeight = totalHeight - offset
    spinner = $('#editorLoadingSpinner')
    spinner.css('top', (newHeight - spinner.height())/2 )
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

Template.editor.created = ->
  MadEye.rendered 'editor'
  #Sometimes the resize happens before everything is ready.
  #It's idempotent and cheap, so do this for safety's sake.
  Meteor.setTimeout ->
    windowSizeChanged()
  , 100


