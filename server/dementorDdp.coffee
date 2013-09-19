MIN_DEMENTOR_VERSION = '0.1.10'
Future = null
Meteor.startup ->
  Future = Npm.require 'fibers/future'

#Methods from dementor
Meteor.methods
  reportError: (error, projectId) ->
    #TODO: Report this somehow.
    console.error "Error from project #{projectId}:", error

  registerProject: (params) ->
    #TODO: Check for dementor version
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
        name: params.project
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
    {version} = getShareContents fileId
    setShareContents fileId, contents, version
    #TODO: Accept warning and send to apogee client

#Methods to dementor
Meteor.methods
  requestFile: (projectId, fileId) ->
    this.unblock()
    console.log "Requesting contents for file #{fileId} and project #{projectId}"
    results = summonDementor(projectId).requestFile fileId
    setShareContents fileId, results.contents
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

MAX_LENGTH = 16777216 #2^24, a large number of chars

getShareContents = (fileId, callback) ->
  throw new Error "fileId required for getShareContents" unless fileId
  #TODO: Source this from MadEye.urls
  url = "#{Meteor.settings.public.bolideUrl}/doc/#{fileId}"
  options =
    timeout: 10*1000
  results = Meteor.http.get url, options
  console.log "File #{fileId} results:", results
  #Meteor downcases the header names, for some reason.
  return {
    version: results.headers['x-ot-version']
    type: results.headers['x-ot-type']
    contents: results.content
  }

setShareContents = (fileId, contents, version=0) ->
  throw new Error "fileId required for setShareContents" unless fileId
  throw new Error "Contents cannot be null for file #{fileId}" unless contents
  #TODO: Source this from MadEye.urls
  url = "#{Meteor.settings.public.bolideUrl}/doc/#{fileId}"
  ops = []
  ops.push {d:MAX_LENGTH} #delete operation, clear contents if any
  ops.push contents #insert operation
  options =
    params: {v:version} #goes in query string because of data
    data: ops
    timeout: 10*1000
  Meteor.http.post url, options



