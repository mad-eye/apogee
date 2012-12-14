class Meteor.Model
  constructor: (collectionName, @modelClass)->
    @collection = new Meteor.Collection collectionName

    @modelClass.prototype.updateJSON = ->
      #there's got to be a better way to do this
      json = JSON.parse(JSON.stringify(@))
      delete json._id
      return json

    self = this
    @modelClass.prototype.save = ->
      if @_id
        self.collection.update @_id, {$set: @updateJSON()}
      else
        self.collection.insert @

    @modelClass.prototype.update = (fields)->
      self.collection.update @_id, {$set: fields}

  findOne: (selector={})->
    rawObject = @collection.findOne(selector)
    if rawObject
      new @modelClass rawObject
    else
      undefined

  find: (selector={})->
    rawObjects = @collection.find(selector).fetch()
    _.map rawObjects, (rawObject)=>
      new @modelClass rawObject

class Setting
  constructor: (rawJSON)->
    _.extend(@, rawJSON)

class Project
  constructor: (rawJSON)->
    _.extend(@, rawJSON)

Files = new Meteor.Model("files", Madeye.File)
Settings = new Meteor.Model("settings", Setting)
Projects = new Meteor.Model("projects", Project)
