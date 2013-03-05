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
        @_id = self.collection.insert @

    @modelClass.prototype.update = (fields)->
      dirty = false
      for key,value of fields
        dirty = true unless @[key] == value
        @[key] = value
      self.collection.update @_id, {$set: fields} if dirty

    @modelClass.prototype.remove = ->
      self.collection.remove @_id if @_id

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

class Project
  constructor: (rawJSON)->
    _.extend(@, rawJSON)

class NewsletterEmail
  constructor: (rawJSON)->
    _.extend(@, rawJSON)

Files = new Meteor.Model("files", Madeye.File)
Projects = new Meteor.Model("projects", Project)
NewsletterEmails = new Meteor.Model("newsletterEmails", NewsletterEmail)
