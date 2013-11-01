@Errors = {}

#Handle meteor-style errors ({reason:, details:})
Errors.handleError = (error, log) ->
  log.error err.details if log
  displayAlert { level: 'error', title: err.reason, message: err.details }
  return err

Errors.wrapShareError = (err, log) ->
  log.warn "Found error from shareJS:", err if log
  details = err.message ? err
  return new Meteor.Error 500, "SyncError", details
  
#Takes httpResponse
Errors.handleNetworkError = (error, response, log) ->
  err = response?.content?.error ? error
  log.error "Network Error:", err.message if log
  Metrics.add
    level:'error'
    message:'networkError'
    error: err.message
  MadEye.transitoryIssues.set 'networkIssues', 10*1000
  return err


projectClosedError =
  level: 'error'
  title: 'Project Closed'
  message: 'The project has been closed on the client.'
  uncloseable: true

fileDeletedWarning =
  level: 'warn'
  title: 'File Deleted'
  message: 'The file has been deleted on the client.'
  uncloseable: true

fileDeletedAndModifiedWarning =
  level: 'warn'
  title: 'File Deleted'
  message: 'The file has been deleted on the client.  If you save it, it will be recreated.'
  uncloseable: true

projectLoadingAlert =
  level: 'info'
  title: 'Project is Loading'
  message: "...we'll be ready in a moment!"
  uncloseable: true

fileModifiedLocallyWarning =
  level: 'warn'
  title: 'File Changed'
  message: 'The file has been changed on the client.  Save it to overwrite the changes, or revert to load the changes.'
  uncloseable: true

networkIssuesWarning =
  level: 'warn'
  title: 'Network Issues'
  message: "We're having trouble with the network.  We'll try to resolve it automatically, but you may want to try again later."
  uncloseable: true

fileIsModifiedLocally = ->
  file = Files.findOne MadEye.editorState?.fileId
  return false unless file and file.fsChecksum? and file.loadChecksum?
  file.fsChecksum != file.loadChecksum

projectIsLoading = ->
  not MadEye.subscriptions?.get('files')?.ready()

Template.projectStatus.projectAlerts = ->
  alerts = []
  alerts.push projectClosedError if projectIsClosed()
  alerts.push fileDeletedAndModifiedWarning if fileIsDeleted()
  alerts.push fileModifiedLocallyWarning if fileIsModifiedLocally()
  alerts.push projectLoadingAlert if projectIsLoading()
  alerts.push networkIssuesWarning if MadEye.transitoryIssues?.has 'networkIssues'
  alerts.push fileDeletedWarning if MadEye.transitoryIssues?.has 'fileDeleted'
  alerts.push MadEye.fileLoader.alert if MadEye.fileLoader.alert
  return alerts


