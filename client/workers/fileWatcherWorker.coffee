log = new MadEye.Logger 'fileWatcher'

Meteor.startup ->
  #If selected (unmodified) file is currently being edited, clear it out.
  Deps.autorun ->
    Files.find(MadEye.fileLoader.editorFileId).observe
      removed: (removedFile) ->
        log.debug "Removed file #{removedFile.path} while being edited"
        MadEye.fileLoader.clearFile()
        MadEye.transitoryIssues.set 'fileDeleted', 10*1000
        

