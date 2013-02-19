# TODO Eliminate need to wrap this in do ->
# https://github.com/meteor/meteor/pull/85

#list of themes and a one liner to try them out one at a time
#themes = ["ace/theme/ambiance", "ace/theme/github", "ace/theme/textmate", "ace/theme/chaos", "ace/theme/idle_fingers", "ace/theme/tomorrow", "ace/theme/chrome", "ace/theme/kr", "ace/theme/tomorrow_night", "ace/theme/clouds", "ace/theme/merbivore", "ace/theme/tomorrow_night_blue", "ace/theme/clouds_midnight", "ace/theme/merbivore_soft", "ace/theme/tomorrow_night_bright", "ace/theme/cobalt", "ace/theme/mono_industrial", "ace/theme/tomorrow_night_eighties", "ace/theme/crimson_editor", "ace/theme/monokai", "ace/theme/twilight", "ace/theme/dawn", "ace/theme/pastel_on_dark", "ace/theme/vibrant_ink", "ace/theme/dreamweaver", "ace/theme/solarized_dark", "ace/theme/xcode", "ace/theme/eclipse", "ace/theme/solarized_light"]
#currentTheme = themes.pop(); ace.edit("editor").setTheme(currentTheme); console.log("current theme is", currentTheme);

do ->

  fileTree = new Madeye.FileTree()

  projectIsClosed = ->
    Projects.findOne()?.closed

  Template.projectStatus.projectIsClosed = ->
    projectIsClosed()

  Template.projectStatus.projectClosedError = ->
    level: 'error'
    title: 'Project Closed'
    message: 'The project has been closed on the client.'
    uncloseable: true

  #Find how many files the server things, so we know if we have them all.
  Meteor.autosubscribe ->
    Meteor.call 'getFileCount', Session.get('projectId'), (err, count)->
      if err then console.error err; return
      Session.set 'fileCount', count

  Template.projectStatus.projectIsLoading = ->
    return not (Projects.findOne()? || Session.equals 'fileCount', Files.collection.find().count())

  Template.projectStatus.projectLoadingAlert = ->
    level: 'info'
    title: 'Project is Loading'
    message: "...we'll be ready in a moment!"
    uncloseable: true

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

  editorState = null

  Meteor.startup ->
    editorState = new EditorState "editor"

    Meteor.autorun ->
      return unless Session.equals("editorRendered", true)
      settings = Settings.findOne()
      return unless settings?
      return if Session.equals "editorFilePath", editorState?.file?.path
      if Session.get "editorFilePath"
        file = Files.findOne {path: Session.get "editorFilePath"}
      return unless file
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
      editorState.loadFile file, "#{settings.bolideUrl}/channel"

  Template.editorChrome.events
    'click button#saveButton' : (event) ->
      console.log "clicked save button"
      Session.set "saving", true
      editorState.save (err) ->
        if err
          #Handle error better.
          console.error "Error in save request:", err
        else
          Session.set "saving", false

  Handlebars.registerHelper "editorFileName", ->
    Session.get "editorFilePath"

  Template.editorChrome.saveButtonMessage = ->
    filePath = Session.get "editorFilePath"
    file = Files.findOne({path: filePath}) if filePath?
    unless file?.modified
      "Saved"
    else if projectIsClosed()
      "Offline"
    else if Session.equals "saving", true
      "Saving..."
    else
      "Save Locally"


  Template.editorChrome.showSaveSpinner = ->
    Session.equals "saving", true

  #FIXME: If a connection is re-established, the file is considered modified==false.
  Template.editorChrome.buttonDisabled = ->
    filePath = Session.get "editorFilePath"
    file = Files.findOne({path: filePath}) if filePath?
    if !file?.modified or Session.equals("saving", true) or projectIsClosed()
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


