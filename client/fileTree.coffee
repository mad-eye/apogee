#extends FileTree from madeye-common (is there a more coffeescriptish way to do this?)

openedDirs = new Meteor.Collection(null)

isOpen = (dirId) ->
  dir = openedDirs.findOne {dirId: dirId}
  if dir?.opened then return true else return false

openDir = (dirId) ->
  dir = openedDirs.findOne {dirId: dirId}
  if dir
    openedDirs.update {dirId: dirId}, {$set: {opened: true}}
  else
    openedDirs.insert {dirId: dirId, opened: true}

closeDir = (dirId) ->
  openedDirs.remove {dirId: dirId}

_.extend Madeye.File.prototype,
  select: ->
    Session.set("selectedFileId", @_id)
    if !@isDir
      Session.set("editorFileId", @_id)
    else
      @toggle()

  isOpen: ->
    isOpen @_id

  isSelected: ->
    Session.equals("selectedFileId", @_id)

  toggle: ->
    if @isOpen() then @close() else @open()

  open: ->
    openDir @_id

  close: ->
    closeDir @_id

  #TODO would be nicer if this was a getter
  extension: ->
    @filename.split(".").pop()
  
  aceMode: ->
    Madeye.ACE_MODES[@extension()]

_.extend Madeye.FileTree.prototype,
  isVisible: (file)->
    parent = @findByPath(file.parentPath) if file.parentPath?
    return true unless parent
    return parent.isOpen() and @isVisible(parent)

