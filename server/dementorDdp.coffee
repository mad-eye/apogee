MIN_DEMENTOR_VERSION = '0.4.2'
MIN_NODE_VERSION = '0.8.18'
semver = Npm.require 'semver'
log = new Logger 'dementorDdp'

#Methods from dementor
Meteor.methods
  #params: {projectId?:, projectName:, version:, dementor:}
  registerProject: (params) ->
    log.debug 'Registering project with', params
    #Scratch projects don't come from a dementor
    unless params.scratch
      checkDementorVersion params.version, params.os
      warning = checkNodeVersion params.nodeVersion
    if params.projectId
      project = Projects.findOne params.projectId
    if project
      project.update
        name: params.projectName
        closed: false
        lastOpened: Date.now()
        version: params.version
    else
      doc =
        name: params.projectName
        closed: false
        lastOpened: Date.now()
        created: Date.now()
        version: params.version
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
    Projects.update projectId, {$set: {closed:true}, $unset: {tunnels:true}}
    MadEye.dismissDementor projectId

  dementorHeartbeat: (projectId) ->
    this.unblock()
    MadEye.touchDementor projectId

  addFile: (file) ->
    this.unblock()
    #TODO what is 'check'?
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
    log.trace "Calling updateFileContents", fileId, contents.substr(0,20)
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

  updateTunnel: (projectId, tunnelName, tunnel) ->
    check projectId, String
    check tunnelName, String
    check tunnel, Object
    log.trace "Updating tunnel #{tunnelName} for #{projectId}", tunnel
    project = Projects.findOne projectId
    project.tunnels ?= {}
    if tunnel
      project.tunnels[tunnelName] = tunnel
    else
      delete project.tunnels[tunnelName]
    project.save()


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

checkDementorVersion = (version, os) ->
  unless version? && semver.gte version, MIN_DEMENTOR_VERSION
    installUrl = Meteor.settings.public.apogeeUrl + '/install'
    message = "Your version #{version} of MadEye is out of date.\n"
    if os
      if os.platform == 'darwin' and os.arch == 'x64'
        supportedOS = true
      else if os.platform == 'linux' and (os.arch == 'x64' or os.arch == 'ia32')
        supportedOS = true

      if supportedOS
        message += "Please run 'curl #{installUrl} | sh' to get the latest."
      else #no new installer for you!
        message += "Please run 'sudo npm update -g madeye' to get the latest."
    else #no os info
      message += """On OS X or Linux, please run 'curl #{installUrl} | sh' to update.
      On other platforms, please run 'sudo npm update -g madeye' to get the latest.
      """
    log.info "Outdated dementor with version #{version}"
    throw MadEye.Errors.new 'VersionOutOfDate', message:message

checkNodeVersion = (version) ->
  unless version? && semver.gte version, MIN_NODE_VERSION
    log.info "Outdated node with version #{version}"
    return "Your Node.js version is less than required (#{MIN_NODE_VERSION}).  Please upgrade to avoid any funny business."
  return undefined

# Cache instructions; don't read from disk each time.
SCRATCH_INSTRUCTIONS = Assets.getText 'scratchProjectInstructions.txt'
NORMAL_INSTRUCTIONS = Assets.getText 'instructions.txt'
addScratchFile = (projectId) ->
  SCRATCH_PATH = "%SCRATCH%"
  ORDERING_PATH = "!!SCRATCH"
  fileId = Files.insert
    path:SCRATCH_PATH
    projectId:projectId
    isDir:false
    scratch:true
    orderingPath:ORDERING_PATH
  log.trace "Added scratch file #{fileId} for #{projectId}"
  project = Projects.findOne projectId
  if project.scratch
    scratchContents = SCRATCH_INSTRUCTIONS
  else
    scratchContents = NORMAL_INSTRUCTIONS
  MadEye.Bolide.createDocument fileId, scratchContents

