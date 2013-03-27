IconsForFile = new Meteor.Collection(null)
 
do ->
  fileTree = new Madeye.FileTree()
    
  Meteor.startup ->
    Meteor.autorun ->
      activeSessionIds = []
      for status in ProjectStatuses.find()
        activeSessionIds.push status.sessionId
        iconForFile = IconsForFile.findOne sessionId:status.sessionId
        data = {path:status.filePath, sessionId:status.sessionId, iconId:status.iconId}
        if iconForFile
          if data.path != iconForFile.path
            IconsForFile.update iconForFile._id, {$set: data}
        else
          IconsForFile.insert data
      IconsForFile.remove {sessionId: {$nin: activeSessionIds}}  
        

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
      iconsForFile = IconsForFile.find({path:file.path}).fetch()
      icons = ("/images/#{USER_ICONS[iconId]}" for {iconId} in iconsForFile)
      return icons

    projectName : ->
      Projects.findOne(Session.get "projectId")?.name ? "New project"

  # Select file
  Template.fileTree.events
    'click li.fileTree-item' : (event) ->
      fileId = event.currentTarget.id
      file = fileTree.findById fileId
      file.select()


