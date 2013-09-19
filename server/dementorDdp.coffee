MIN_DEMENTOR_VERSION = '0.1.10'
Future = null
Meteor.startup ->
  Future = Npm.require 'fibers/future'

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

Meteor.methods
  requestFile: (projectId, fileId) ->
    console.log "Requesting contents for file #{fileId} and project #{projectId}"
    this.unblock()
    results = summonDementor(projectId).requestFile fileId
    console.log "Got requestFile results:", results
    setShareContents fileId, results.contents
    return results

  saveFile: (projectId, fileId, contents) ->
    console.log "Saving contents for file #{fileId} and project #{projectId}"
    this.unblock()
    summonDementor(projectId).saveFile fileId, contents

MAX_LENGTH = 16777216 #2^24, a large number of chars

setShareContents = (fileId, contents, callback) ->
  throw new Error "fileId required for setShareContents" unless fileId
  throw new Error "Contents cannot be null for file #{fileId}" unless contents
  url = "#{Meteor.settings.public.bolideUrl}/doc/#{fileId}"
  ops = []
  ops.push {d:MAX_LENGTH} #delete operation, clear contents if any
  ops.push contents #insert operation
  options =
    params: {v:0} #goes in query string because of data
    data: ops
    timeout: 10*1000
  Meteor.http.post url, options



