class MeteorModel
  constructor: (data, @collection)->
    _.extend @, data

  updateJSON: ->
    #there's got to be a better way to do this
    json = JSON.parse(JSON.stringify(@))
    delete json._id
    return json

  save: ->
    if @_id
      @collection.update @_id, {$set: @updateJSON()}
    else
      @_id = @collection.insert @

  update: (fields)->
    dirty = false
    for key,value of fields
      dirty = true unless @[key] == value
      @[key] = value
    @collection.update @_id, {$set: fields} if dirty

  remove: ->
    @collection.remove @_id if @_id
