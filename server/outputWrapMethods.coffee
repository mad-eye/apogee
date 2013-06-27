Meteor.publish 'outputs', (projectId) ->
  Outputs.find
    projectId: projectId

console.log "Registering output methods"
Meteor.methods
  output: (projectId, type, data) ->
    console.log "Recording output for #{projectId}:", data
    Outputs.insert {projectId, type, data}

