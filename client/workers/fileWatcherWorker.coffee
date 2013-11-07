log = new Logger 'fileWatcher'

Meteor.startup ->
  #If selected (unmodified) file is currently being edited, clear it out.
  Deps.autorun ->
    @name 'set fileDeleted warning'
    #FIXME: This triggers for initial load of the scratch file on a scratch project.
    Files.find(MadEye.fileLoader.editorFileId).observe
      removed: (removedFile) ->
        log.debug "Removed file #{removedFile.path} while being edited"
        MadEye.fileLoader.clearFile()
        MadEye.transitoryIssues.set 'fileDeleted', 10*1000
        

  #Go to a scratch file if we haven't selected anything.
  #Is this dangerous?
  Deps.autorun ->
    return unless MadEye.subscriptions.get('files')?.ready()
    return if MadEye.fileLoader.selectedFileId
    scratchFile = Files.findOne {projectId: getProjectId(), scratch: true}
    log.trace 'No file selected; loading scratch file'
    MadEye.fileLoader.loadId = scratchFile._id if scratchFile


