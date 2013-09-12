MIN_DEMENTOR_VERSION = '0.1.10'


Meteor.methods
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

###
#These are commands sent to dementor instances.

Commands = new Meteor.Collection 'commands'

Meteor.publish 'commands', (projectId) ->
  Commands.find projectId:projectId

Commands.allow
  insert: (userId, doc) -> true
  remove: (userId, doc) -> true

Meteor.methods
  command: (projectId, command) ->
    console.log "Inserting into #{projectId}: #{command}"
    Commands.insert {projectId, command, timestamp: Date.now()}

  #receivedCommand: (commandId) ->
    #console.log "removing command", commandId
    #Commands.remove commandId
###
