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
      Meteor.Router.to("/edit/#{@projectId}/#{@path}")
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

  visibleParent: ->
    lastVisible = this
    parentPath = @parentPath
    while parentPath
      parent = Files.findOne({path: @parentPath})
      lastVisible = parent unless parent.isOpen()
      parentPath = parent.parentPath
    return lastVisible


  #TODO would be nicer if this was a getter
  extension: ->
    tokens = @filename.split '.'
    if tokens.length > 1 then tokens.pop() else null
  
  aceMode: ->
    extension = @extension()?.toLowerCase()
    if extension
      Madeye.ACE_MODES[extension]
    else
      switch @filename
        when 'Makefile' then 'makefile'
        when 'Cakefile' then 'coffee'
        when 'Rakefile', 'Gemfile' then 'ruby'
        #TODO: Check for #!
        else null
        

  openParents: ->
    if @parentPath
      parent = Files.findOne({path: @parentPath})
      parent.open()
      parent.openParents()

_.extend Madeye.FileTree.prototype,
  isVisible: (file)->
    parent = @findByPath(file.parentPath) if file.parentPath?
    return true unless parent
    return parent.isOpen() and @isVisible(parent)


