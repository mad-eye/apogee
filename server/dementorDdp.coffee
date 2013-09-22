MIN_DEMENTOR_VERSION = '0.2.0'
MIN_NODE_VERSION = '0.8.18'
semver = Npm.require 'semver'

#Methods from dementor
Meteor.methods
  reportError: (error, projectId) ->
    #TODO: Report this somehow.
    console.error "Error from project #{projectId}:", error

  #params: {projectId?:, projectName:, version:}
  registerProject: (params) ->
    checkDementorVersion params.version
    #TODO: Check for node version
    if params.projectId
      project = Projects.findOne params.projectId
    if project
      project.update
        name: params.projectName
        closed: false
        lastOpened: Date.now()
    else
      doc =
        name: params.projectName
        closed: false
        lastOpened: Date.now()
        created: Date.now()
      doc._id = params.projectId if params.projectId
      project = Project.create doc
    return project._id

  closeProject: (projectId) ->
    Projects.update projectId, closed:true

  addFile: (file) ->
    Files.insert file

  removeFile: (fileId) ->
    console.log "Calling removeFile", fileId
    Files.remove fileId

  updateFile: (fileId, modifier) ->
    console.log "Calling updateFile", fileId, modifier
    Files.update fileId, modifier

  updateFileContents: (fileId, contents) ->
    console.log "Calling updateFileContents", fileId, contents
    try
      {version} = MadEye.Bolide.getShareContents fileId
    catch e
      if e.response.statusCode == 404
        console.warn "Trying to get share doc for #{fileId}, but it doesn't exist."
      else
        console.error "Error in getShareContents:", e
        #TODO: Return certain errors
      return
    setShareContents fileId, contents, version
    #TODO: Accept warning and send to apogee client

#Methods to dementor
Meteor.methods
  requestFile: (projectId, fileId) ->
    this.unblock()
    console.log "Requesting contents for file #{fileId} and project #{projectId}"
    results = summonDementor(projectId).requestFile fileId
    MadEye.Bolide.setShareContents fileId, results.contents
    #Contents might be huge, save some download time
    delete results.contents
    return results

  saveFile: (projectId, fileId, contents) ->
    this.unblock()
    console.log "Saving contents for file #{fileId} and project #{projectId}"
    summonDementor(projectId).saveFile fileId, contents

  revertFile: (projectId, fileId, version) ->
    this.unblock()
    #XXX: Could get version from getShareContents, at the cost of a http round-trip
    console.log "Reverting contents for file #{fileId} and project #{projectId}"
    results = summonDementor(projectId).requestFile fileId
    setShareContents fileId, results.contents, version
    return results

checkDementorVersion = (version) ->
  unless version? && semver.gte version, MIN_DEMENTOR_VERSION
    throw MadEye.Errors.new 'VersionOutOfDate', version:version
