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
    
class ProjectStatus
  constructor: (rawJSON) ->
    _.extend(@, rawJSON)

Files = new Meteor.Model("files", Madeye.File)
Projects = new Meteor.Model("projects", Project)
NewsletterEmails = new Meteor.Model("newsletterEmails", NewsletterEmail)
ProjectStatuses = new Meteor.Model("projectStatus", ProjectStatus)


#return a map between file paths and open sharejs session ids
if Meteor.isClient
  do ->
    sessionsDep = new Deps.Dependency
    ProjectStatuses.getSessions = ->
      projectId = Session.get "projectId"
      Deps.depend sessionsDep
      result = {}
      Deps.nonreactive ->
        statuses = ProjectStatuses.find {projectId}
        for status in statuses
          continue unless status.filepath
          result[status.filepath] ?= []
          result[status.filepath].push status
      return result

    Meteor.setInterval ->
      sessionId = Session.get "sessionId"
      projectId = Session.get "projectId"
      return unless sessionId and projectId
      status = ProjectStatuses.findOne {sessionId, projectId}
      status?.update {heartbeat: Date.now()}
    , 2*1000

    Deps.autorun ->
      #TODO this seems bolierplatey..
      sessionId = Session.get("sessionId")
      projectId = Session.get("projectId")
      return unless Session.equals("editorRendered", true) and sessionId and projectId
      projectStatus = ProjectStatuses.findOne {sessionId, projectId}
      return unless projectStatus
      projectStatus.update {filepath: editorState.getPath(), connectionId: editorState.getConnectionId()}

    queryHandle = null
    Deps.autorun (computation)->
      return unless Session.get("projectId")?
      projectId = Session.get("projectId")
      Deps.nonreactive ->
        queryHandle?.stop()
        unless Session.get("sessionId")?
          Session.set "sessionId", Meteor.uuid()
        sessionId = Session.get "sessionId"
        Meteor.call "createProjectStatus", sessionId, projectId

        cursor = ProjectStatuses.collection.find {projectId}
        queryHandle = cursor.observeChanges
          added: (id, fields)->
            console.log "ADDED", id, fields
            sessionsDep.changed()

          changed: (id, fields)->
            console.log "CHANGED", id, fields if fields.filepath?
            sessionsDep.changed() if fields.filepath?

          removed: (id, fields)->
            console.log "REMOVED", id, fields
            sessionsDep.changed()