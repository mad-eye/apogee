do ->
  fileTree = new Madeye.FileTree()
    
  Template.fileTree.helpers
    files : ->
      fileTree.setFiles Files.collection.find()
      _.filter fileTree.files, (file)->
        fileTree.isVisible(file)

    fileEntryClass : ->
      clazz = "fileTree-item"
      if @isDir
        clazz += " directory " + if @isOpen() then "open" else "closed"
      else
        clazz += " file"
      clazz += " level" + this.depth
      clazz += " selected" if this.isSelected()
      clazz += " modified" if this.modified
      return clazz

    usersInFile: (file) ->
      _.map ProjectStatuses.getSessions()[file.path], (iconId)->
        "/images/#{USER_ICONS[iconId]}"

    projectName : ->
      Projects.findOne(Session.get "projectId")?.name ? "New project"

  # Select file
  Template.fileTree.events
    'click li.fileTree-item' : (event) ->
      fileId = event.currentTarget.id
      file = fileTree.findById fileId
      file.select()


