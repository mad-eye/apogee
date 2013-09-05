#Find how many files the server things, so we know if we have them all.
Deps.autorun ->
  @name 'set fileCount'
  Meteor.call 'getFileCount', Session.get('projectId'), (err, count)->
    if err
      Metrics.add
        level:'error'
        message:'getFileCount'
      console.error err
      return
    Session.set 'fileCount', count

Meteor.startup ->
  #If selected (unmodified) file is currently being edited, clear it out.
  Deps.autorun ->
    @name 'set fileDeleted warning'
    #FIXME: This triggers for initial load of the scratch file on a scratch project.
    Files.find(MadEye.fileLoader.editorFileId).observe
      removed: (removedFile) ->
        MadEye.fileLoader.clearFile()
        MadEye.transitoryIssues.set 'fileDeleted', 10*1000
        

