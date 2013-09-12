MIN_DEMENTOR_VERSION = '0.1.10'


Meteor.methods
  'registerProject': (params) ->
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

  'addFile': (file) ->
    Files.insert file

  'removeFile': (fileId) ->
    console.log "Calling removeFile", fileId
    Files.remove fileId
