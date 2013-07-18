Template.output.helpers
  outputs: ->
    Outputs.find({}, {sort:{timestamp:1}})
