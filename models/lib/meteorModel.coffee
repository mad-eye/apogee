class MadEye.Model
  constructor: (data)->
    _.extend @, data
    #@collection needs to be set after creating the Collection.

  #Remove circular references and functions and the like.
  _safeJSON: ->
    #there's got to be a better way to do this
    json = JSON.parse(JSON.stringify(@))
    delete json._id
    return json

  save: ->
    if @_id
      #We should replace the entire document, to catch deletions
      @collection.update @_id, @_safeJSON()
    else
      @_id = @collection.insert @_safeJSON()

  update: (fields)->
    dirty = false
    for key,value of fields
      dirty = true unless @[key] == value
      @[key] = value
    @collection.update @_id, {$set: fields} if dirty

  remove: ->
    @collection.remove @_id if @_id

  #TODO: Accept an array
  @create: (data) ->
    #Need to use @prototype.collection for class methods
    id = @prototype.collection.insert data
    return @prototype.collection.findOne id
