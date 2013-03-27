IconsForFile = new Meteor.Collection(null)
 
do ->
  fileTree = new Madeye.FileTree()
  
  #not deep equal, not caring about sorting or performance (used for small n)
  areSetsEqual = (arr1, arr2) ->
    # null == null as well
    return true if arr1 == arr2
    return false unless arr1? and arr2?
    return false unless arr1.length == arr2.length
    items1 = {}; items1[e] = true for e in arr1
    items2 = {}; items2[e] = true for e in arr2
    return _.isEqual items1, items2
    
  #fileIcons: {path:, iconIds:[]}
  Meteor.startup ->
    Meteor.autorun ->
      fileIcons = {}
      for status in ProjectStatuses.find()
        path = status.filePath
        continue unless path
        fileIcons[path] ?= []
        fileIcons[path].push status.iconId

      #console.log "Found fileIcons from projectStatuses:", fileIcons
      for path, iconIds of fileIcons
        iconsForFile = IconsForFile.findOne({path})
        existingIds = iconsForFile?.iconIds
        unless areSetsEqual(iconIds, existingIds)
          if iconsForFile
            IconsForFile.update {path:path}, {$set: {iconIds:iconIds}}
          else
            IconsForFile.insert {path, iconIds}

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
      iconIds = IconsForFile.findOne({path:file.path})?.iconIds
      return unless iconIds?
      console.log "Found icons #{iconIds} for path #{file.path}"
      icons = ("/images/#{USER_ICONS[iconId]}" for iconId in iconIds)
      console.log "Found icon paths:", icons
      return icons

    projectName : ->
      Projects.findOne(Session.get "projectId")?.name ? "New project"

  # Select file
  Template.fileTree.events
    'click li.fileTree-item' : (event) ->
      fileId = event.currentTarget.id
      file = fileTree.findById fileId
      file.select()


