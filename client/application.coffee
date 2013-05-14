#for urls of the form /edit/PROJECT_ID/PATH_TO_FILE#LINE_NUMBER
#PATH_TO_FILE and LINE_NUMBER are optional
#editRegex = /\/edit\/([-0-9a-f]+)\/?([^#]*)#?([0-9]*)?/
#TODO should probably OR the line and session fields
@editRegex = /\/(edit|interview)\/([-\w]+)\/?([^#]*)#?(?:L([0-9]*))?(?:S([0-9a-f-]*))?/

#soon..
#MadEye.editorState = new EditorState "editor"
#MadEye.fileTree = new FileTree

if Meteor.settings.public.googleAnalyticsId
  window._gaq = window._gaq || []
  _gaq.push ['_setAccount', Meteor.settings.public.googleAnalyticsId]

do ->
  #TODO figure out how to eliminate all the duplicate recordView calls
  recordView = (params)->
    @Events.record "pageView", params
    _gaq.push ['_trackPageview'] if _gaq?

  Meteor.Router.add editRegex, (page, projectId, filePath, lineNumber, connectionId)->
    Deps.nonreactive ->
      isHangout = false
      #TODO record type..edit/interview/scratch
      if /hangout=true/.exec(document.location.href.split("?")[1])
        Session.set "isHangout", true
        isHangout = true
      recordView {page, projectId, filePath, hangout: isHangout}
      Session.set 'projectId', projectId
      Metrics.add {message:'load', filePath, lineNumber, connectionId, isHangout}
      window.editorState ?= new EditorState "editor"
      
      MadEye.fileLoader.loadPath = filePath
      #This editorFilePath probably isn't set yet, because we haven't flushed
      fileTree.open MadEye.fileLoader.editorFilePath, true

    "edit"

  scratchPath = "SCRATCH.rb"

  Meteor.Router.add
    '/':  ->
      recordView page: "home"
      "home"
      
    '/get-started': ->
      recordView page: "get-started"
      "getStarted"

    '/login': ->

    '/tests': ->
      "tests"

    '/tos': ->
      recordView page: "tos"
      'tos'

    '/faq': ->
      recordView page: "faq"
      'faq'

    '/interview': ->
      #TODO add more info here..
      recordView page: "create interview"
      project = new Project()
      project.interview = true
      project.save()

      Deps.nonreactive ->
        file = new MadEye.File
        file.projectId = project._id
        file.path = scratchPath
        file.scratch = true
        file.save()
      Meteor.setTimeout ->
        Meteor.Router.to "/edit/#{project._id}/#{scratchPath}"
      , 0

    '/scratch': ->
      #TODO add more info here..
      # recordView page: "create scratch"
      project = new Project()
      project.scratch = true
      project.save()

      Deps.nonreactive ->
        file = new MadEye.File
        file.projectId = project._id
        file.path = scratchPath
        file.scratch = true
        file.save()
      Meteor.setTimeout ->
        Meteor.Router.to "/edit/#{project._id}/#{scratchPath}"
      , 0

    '/unlinked-hangout': ->
      recordView page: "unlinked hangout"
      Session.set "isHangout", true
      'unlinkedHangout'

    '*': ->
      recordView page: "missing"
      "missing"

Deps.autorun ->
  projectId = Session.get "projectId"
  return unless projectId
  Meteor.subscribe "files", projectId
  Meteor.subscribe "projects", projectId
  Meteor.subscribe "projectStatuses", projectId
  Meteor.subscribe "scriptOutputs", projectId
  Meteor.subscribe "workspaces", projectId

Deps.autorun ->
  return if Meteor.loggingIn()
  Meteor.loginAnonymously() unless Meteor.user()

#TODO: Replace this with MadEye.transitoryIssues
@transitoryIssues = null
Meteor.startup ->
  transitoryIssues = new TransitoryIssues

