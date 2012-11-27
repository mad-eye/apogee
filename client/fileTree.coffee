#extends FileTree from madeye-common (is there a more coffeescriptish way to do this?)

_.extend Madeye.File.prototype,
  select: ->
    Session.set("selectedFileId", @_id)
    if !@isDir
      Session.set("editorFileId", @_id)
    else
      @toggle()

  isOpen: ->
    openDirs = Session.get("openDirs") || {}
    openDirs[@_id]

  isSelected: ->
    Session.equals("selectedFileId", @_id)

  toggle: ->
    if @isOpen() then @close() else @open()

  open: ->
    openDirs = Session.get("openDirs") || {}
    openDirs[@_id] = true
    Session.set "openDirs", openDirs

  close: ->
    openDirs = Session.get("openDirs") || {}
    delete openDirs[@_id]
    Session.set "openDirs", openDirs

  fetchBody: ->
    settings = Settings.findOne()
    url = "http://#{settings.httpHost}:#{settings.httpPort}"
    url = "#{url}/project/#{Projects.findOne()._id}/file/#{@_id}"
    #TODO don't call this once sharejs has the data..
    console.log "URL is #{url}"
    Meteor.http.get url, ->
      console.log "callback received"

_.extend Madeye.FileTree.prototype,
  isVisible: (file)->
    parentPath = /(.*)\//.exec(file.path)[1]
    parent = @findByPath(parentPath)
    return true unless parent
    return parent.isOpen() and @isVisible(parent)