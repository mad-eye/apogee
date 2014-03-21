# All the various resize logic goes here, instead of scattered
# and cluttering up the controllers.

#Deps to handle resizes.  Might be nice to have reactive DOM elts.
windowDep = new Deps.Dependency()
@windowSizeChanged = (flush) ->
  windowDep.changed()
  Deps.flush() if flush

baseSpacing = 10; #px

Meteor.startup ->
  #Trigger initial size calculations
  windowDep.changed()

  #Set up windowDep listening to window resize
  Deps.autorun (computation) ->
    #XXX: Is this necessary?  For terminal/editor only windows, these might not
    #be rendered.
    # Presumably it is cheaper to only do this on pages with the resizer.
    #return unless MadEye.isRendered 'editor', 'fileTree', 'statusBar'
    $(window).resize ->
      windowSizeChanged true
    computation.stop()

  #Filetree resize
  Deps.autorun ->
    return unless isEditorPage() and MadEye.isRendered 'fileTree'
    windowDep.depend()
    windowHeight = $(window).height()

    $fileTreeContainer = $("#fileTreeContainer")
    return unless $fileTreeContainer and $fileTreeContainer.offset() #homepage doesn't have filetree
    fileTreeTop = $fileTreeContainer.offset().top
    newFileTreeHeight = Math.min(windowHeight - fileTreeTop - 2*baseSpacing, $("#fileTree").height())
    $fileTreeContainer.height(newFileTreeHeight)

