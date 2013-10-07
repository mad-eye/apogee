MIN_DEMENTOR_VERSION = '0.2.0'
MIN_NODE_VERSION = '0.8.18'
semver = Npm.require 'semver'
log = new MadEye.Logger 'dementorDdp'

#Methods from dementor
Meteor.methods
  #params: {projectId?:, projectName:, version:, dementor:}
  registerProject: (params) ->
    log.trace 'Registering project with', params
    #Scratch projects don't come from a dementor
    unless params.scratch
      checkDementorVersion params.version
      warning = checkNodeVersion params.nodeVersion
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
      doc.scratch = params.scratch if params.scratch?
      project = Project.create doc
      addScratchFile project._id
    if params.dementor
      MadEye.touchDementor project._id
    result = projectId: project._id
    result.warning = warning if warning
    return result


  closeProject: (projectId) ->
    log.trace "Closing project #{projectId}"
    Projects.update projectId, {$set: {closed:true}}
    MadEye.dismissDementor projectId

  dementorHeartbeat: (projectId) ->
    this.unblock()
    MadEye.touchDementor projectId

  addFile: (file) ->
    this.unblock()
    check file, Match.ObjectIncluding path:String, orderingPath:String
    Files.insert file

  markDirectoryLoaded: (projectId, path)->
    ActiveDirectories.update({projectId:projectId, path:path}, {$set: {loaded: true}})

  removeFile: (fileId) ->
    this.unblock()
    log.trace "Calling removeFile", fileId
    check fileId, String
    Files.remove fileId

  updateFile: (fileId, modifier) ->
    this.unblock()
    log.trace "Calling updateFile", fileId, modifier
    check fileId, String
    check modifier, Object
    Files.update fileId, modifier

  updateFileContents: (fileId, contents) ->
    this.unblock()
    log.trace "Calling updateFileContents", fileId, contents
    check fileId, String
    check contents, String
    try
      {version} = MadEye.Bolide.getShareContents fileId
    catch e
      if e.response.statusCode == 404
        #XXX: Should we assume version=0 and set the contents here?
        log.warn "Trying to get share doc for #{fileId}, but it doesn't exist."
        return
      else
        log.error "Error in getShareContents:", e
        #Client should be alerted that something went wrong.
        throw e
    MadEye.Bolide.setShareContents fileId, contents, version

  addTunnels: (projectId, tunnels) ->
    check projectId, String
    check tunnels, Object
    Projects.update projectId, {$set: {tunnels}}


#Methods to dementor
Meteor.methods
  requestFile: (projectId, fileId) ->
    this.unblock()
    log.trace "Requesting contents for file #{fileId} and project #{projectId}"
    project = Projects.findOne projectId
    if project.impressJS
      results = MadEye.Azkaban.requestStaticFile projectId, fileId
    else
      results = MadEye.summonDementor(projectId).requestFile fileId
      MadEye.Bolide.setShareContents fileId, results.contents
      #Contents might be huge, save some download time
      delete results.contents
    return results

  saveFile: (projectId, fileId, contents) ->
    this.unblock()
    log.debug "Saving contents for file #{fileId} and project #{projectId}"
    project = Projects.findOne projectId
    if project.impressJS
      MadEye.Azkaban.saveStaticFile projectId, fileId, contents
    else
      MadEye.summonDementor(projectId).saveFile fileId, contents

  revertFile: (projectId, fileId, version) ->
    this.unblock()
    log.debug "Reverting contents for file #{fileId} and project #{projectId}"
    project = Projects.findOne projectId
    if project.impressJS
      results = MadEye.Azkaban.revertStaticFile projectId, fileId
    else
      #XXX: Could get version from getShareContents, at the cost of a http round-trip
      results = MadEye.summonDementor(projectId).requestFile fileId
      MadEye.Bolide.setShareContents fileId, results.contents, version
    return results

checkDementorVersion = (version) ->
  unless version? && semver.gte version, MIN_DEMENTOR_VERSION
    log.info "Outdated dementor with version #{version}"
    throw MadEye.Errors.new 'VersionOutOfDate', version:version

checkNodeVersion = (version) ->
  unless version? && semver.gte version, MIN_NODE_VERSION
    log.info "Outdated node with version #{version}"
    return "Your Node.js version is less than required (#{MIN_NODE_VERSION}).  Please upgrade to avoid any funny business."
  return undefined

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

