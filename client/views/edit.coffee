# TODO Eliminate need to wrap this in do ->
# https://github.com/meteor/meteor/pull/85

#list of themes and a one liner to try them out one at a time
#themes = ["ace/theme/ambiance", "ace/theme/github", "ace/theme/textmate", "ace/theme/chaos", "ace/theme/idle_fingers", "ace/theme/tomorrow", "ace/theme/chrome", "ace/theme/kr", "ace/theme/tomorrow_night", "ace/theme/clouds", "ace/theme/merbivore", "ace/theme/tomorrow_night_blue", "ace/theme/clouds_midnight", "ace/theme/merbivore_soft", "ace/theme/tomorrow_night_bright", "ace/theme/cobalt", "ace/theme/mono_industrial", "ace/theme/tomorrow_night_eighties", "ace/theme/crimson_editor", "ace/theme/monokai", "ace/theme/twilight", "ace/theme/dawn", "ace/theme/pastel_on_dark", "ace/theme/vibrant_ink", "ace/theme/dreamweaver", "ace/theme/solarized_dark", "ace/theme/xcode", "ace/theme/eclipse", "ace/theme/solarized_light"]
#currentTheme = themes.pop(); ace.edit("editor").setTheme(currentTheme); console.log("current theme is", currentTheme);

handleShareError: (err) ->
  message = err.message ? err
  Metrics.add
    level:'error'
    message:'shareJsError'
    error: message
  displayAlert { level: 'error', message: message }
  
projectClosedError =
  level: 'error'
  title: 'Project Closed'
  message: 'The project has been closed on the client.'
  uncloseable: true

fileDeletedWarning =
  level: 'warn'
  title: 'File Deleted'
  message: 'The file has been deleted on the client.  If you save it, it will be recreated.'
  uncloseable: true

projectLoadingAlert =
  level: 'info'
  title: 'Project is Loading'
  message: "...we'll be ready in a moment!"
  uncloseable: true

fileModifiedLocallyWarning =
  level: 'warn'
  title: 'File Changed'
  message: 'The file has been changed on the client.  Save it to overwrite the changes, or revert to load the changes.'
  uncloseable: true

networkIssuesWarning =
  level: 'warn'
  title: 'Network Issues'
  message: "We're having trouble with the network.  We'll try to resolve it automatically, but you may want to try again later."
  uncloseable: true

do ->

  fileTree = new Madeye.FileTree()

  projectIsClosed = ->
    Projects.findOne()?.closed
  
  fileIsDeleted = ->
    Files.findOne(path:editorState.getPath())?.removed

  Handlebars.registerHelper "fileIsDeleted", ->
    fileIsDeleted()

  fileIsModifiedLocally = ->
    Files.findOne(path:editorState.getPath())?.modified_locally

  projectIsLoading = ->
    not (Projects.findOne()? || Session.equals 'fileCount', Files.collection.find().count())

  Template.projectStatus.projectAlerts = ->
    alerts = []
    alerts.push projectClosedError if projectIsClosed()
    alerts.push fileDeletedWarning if fileIsDeleted()
    alerts.push fileModifiedLocallyWarning if fileIsModifiedLocally()
    alerts.push projectLoadingAlert if projectIsLoading()
    alerts.push networkIssuesWarning if transitoryIssues?.has 'networkIssues'
    return alerts

  #Find how many files the server things, so we know if we have them all.
  Meteor.autosubscribe ->
    Meteor.call 'getFileCount', Session.get('projectId'), (err, count)->
      if err
        Metrics.add
          level:'error'
          message:'getFileCount'
        console.error err
        return
      Session.set 'fileCount', count

  Template.fileTree.files = ->
    fileTree.setFiles Files.collection.find()
    _.filter fileTree.files, (file)->
      fileTree.isVisible(file)

  Template.fileTree.fileEntryClass = ->
    clazz = "fileTree-item"
    if @isDir
      clazz += " directory " + if @isOpen() then "open" else "closed"
    else
      clazz += " file"
    clazz += " level" + this.depth
    clazz += " selected" if this.isSelected()
    clazz += " modified" if this.modified
    return clazz

  Template.fileTree.projectName = ->
    Projects.findOne()?.name ? "New project"

  # Select file
  Template.fileTree.events
    'click li.fileTree-item' : (event) ->
      fileId = event.currentTarget.id
      file = fileTree.findById fileId
      file.select()

  Template.editor.preserve("#editor")

  Template.editor.rendered = ->
    Session.set("editorRendered", true)
    resizeEditor()

  Meteor.startup ->
    Meteor.autorun ->
      return unless Session.equals("editorRendered", true)
      filePath = editorState?.getPath()
      return unless filePath?
      file = Files.findOne path:filePath
      return unless file and file._id != editorState.file?._id
      #TODO less hacky way to do this?
      #selectedFilePath?
      Session.set "selectedFileId", file._id
      file.openParents()
      if file.isBinary
        displayAlert
          level: "error"
          title: "Unable to load binary file"
          message: file.path
        return
      editorState.loadFile file

  Template.editorChrome.events
    'click #revertFile': (event) ->
      Session.set "working", true
      editorState.revertFile (error)->
        Session.set "working", false

    'click #discardFile': (event) ->
      Metrics.add
        message:'discardFile'
        fileId: editorState?.file?._id
        filePath: editorState?.file?.path #don't want reactivity
      editorState.file.remove()
      editorState.file = null
      editorState.setPath ""

    'click #saveImage' : (event) ->
      #console.log "clicked save button"
      Session.set "working", true
      editorState.save (err) ->
        if err
          #Handle error better.
          console.error "Error in save request:", err
        Session.set "working", false

  Handlebars.registerHelper "editorFileName", ->
    editorState?.getPath()

  Handlebars.registerHelper "editorIsLoading", ->
    Session.equals "editorIsLoading", true

  Template.editorChrome.showSaveSpinner = ->
    Session.equals "working", true

  #FIXME: If a connection is re-established, the file is considered modified==false.
  Template.editorChrome.buttonDisabled = ->
    filePath = editorState.getPath()
    file = Files.findOne({path: filePath}) if filePath?
    if !file?.modified or Session.equals("working", true) or projectIsClosed()
      "disabled"
    else
      ""

  resizeEditor = ->
    editorTop = $("#editor").position().top
    editorLeft = $("#editor").position().left
    windowHeight = $(window).height()
    windowWidth = $(window).width()
    newHeight = windowHeight - editorTop - 20
    newWidth = windowWidth - editorLeft - 20
    $("#editor").height(newHeight)
    $("#editor").width(newWidth)
    ace.edit("editor").resize()

  Meteor.autorun ->
    return unless Session.equals "editorRendered", true
    $(window).resize ->
      resizeEditor()

