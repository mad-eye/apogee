MIN_DEMENTOR_VERSION = '0.2.0'
MIN_NODE_VERSION = '0.8.18'
semver = Npm.require 'semver'
log = new MadEye.Logger 'dementorDdp'

#Methods from dementor
Meteor.methods
  #params: {projectId?:, projectName:, version:}
  registerProject: (params) ->
    log.trace 'Registering project with', params
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
      addScratchFile project._id
    return project._id

  closeProject: (projectId) ->
    Projects.update projectId, closed:true

  addFile: (file) ->
    Files.insert file

  removeFile: (fileId) ->
    log.trace "Calling removeFile", fileId
    Files.remove fileId

  updateFile: (fileId, modifier) ->
    log.trace "Calling updateFile", fileId, modifier
    Files.update fileId, modifier

  updateFileContents: (fileId, contents) ->
    log.trace "Calling updateFileContents", fileId, contents
    try
      {version} = MadEye.Bolide.getShareContents fileId
    catch e
      if e.response.statusCode == 404
        log.warn "Trying to get share doc for #{fileId}, but it doesn't exist."
        return
      else
        log.error "Error in getShareContents:", e
        #Client should be alerted that something went wrong.
        throw e
    MadEye.Bolide.setShareContents fileId, contents, version
    #TODO: Accept warning and send to apogee client

#Methods to dementor
Meteor.methods
  requestFile: (projectId, fileId) ->
    this.unblock()
    log.trace "Requesting contents for file #{fileId} and project #{projectId}"
    results = MadEye.summonDementor(projectId).requestFile fileId
    MadEye.Bolide.setShareContents fileId, results.contents
    #Contents might be huge, save some download time
    delete results.contents
    return results

  saveFile: (projectId, fileId, contents) ->
    this.unblock()
    log.debug "Saving contents for file #{fileId} and project #{projectId}"
    MadEye.summonDementor(projectId).saveFile fileId, contents

  revertFile: (projectId, fileId, version) ->
    this.unblock()
    log.debug "Reverting contents for file #{fileId} and project #{projectId}"
    #XXX: Could get version from getShareContents, at the cost of a http round-trip
    results = MadEye.summonDementor(projectId).requestFile fileId
    MadEye.Bolide.setShareContents fileId, results.contents, version
    return results

checkDementorVersion = (version) ->
  unless version? && semver.gte version, MIN_DEMENTOR_VERSION
    log.info "Outdated dementor with version #{version}"
    throw MadEye.Errors.new 'VersionOutOfDate', version:version

addScratchFile = (projectId) ->
  SCRATCH_PATH = "%SCRATCH%"
  ORDERING_PATH = "!!SCRATCH"
  fileId = Files.insert
    path:SCRATCH_PATH
    projectId:projectId
    isDir:false
    scratch:true
    orderingPath:ORDERING_PATH
  log.debug "Added scratch file #{fileId} for #{projectId}"


