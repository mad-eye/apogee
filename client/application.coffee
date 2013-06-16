#for urls of the form /edit/PROJECT_ID/PATH_TO_FILE#LINE_NUMBER
#PATH_TO_FILE and LINE_NUMBER are optional
#editRegex = /\/edit\/([-0-9a-f]+)\/?([^#]*)#?([0-9]*)?/
#TODO should probably OR the line and session fields
@editRegex = /\/(edit|interview|editImpressJS)\/([-\w]+)\/?([^#]*)#?(?:L([0-9]*))?(?:S([0-9a-f-]*))?/
@transitoryIssues = null

@groupA = (testName)->
  return null unless Meteor.userId()
  return MadEye.crc32("#{Meteor.userId()}#{testName}") % 2 == 0

@groupB = (testName)->
  return null unless Meteor.userId()
  return MadEye.crc32("#{Meteor.userId()}#{testName}") % 2 != 0

MadEye.fileLoader = new FileLoader()

#queryString example: '?a=b&c&d=&a=f'
#For right now, we ignore multiple values for a given param
getQueryParams = (queryString) ->
  params = {}
  return params unless queryString and queryString.length > 1
  queryString = queryString.substr 1
  queryTokens = queryString.split '&'
  for token in queryTokens
    [key, value] = token.split '='
    value ?= true
    params[key] = value
  return params

registerHangout = (projectId, hangoutUrl) ->
  return unless hangoutUrl
  registerHangoutUrl = Meteor.settings.public.azkabanUrl + "/hangout/" + projectId
  Meteor.http.put registerHangoutUrl, {
      data: {hangoutUrl}
      headers: {'Content-Type':'application/json'}
      timeout: 5*1000
    }, (error,response) =>
      console.error "Registering hangout url failed.", error if error

if Meteor.settings.public.googleAnalyticsId
  window._gaq = window._gaq || []
  _gaq.push ['_setAccount', Meteor.settings.public.googleAnalyticsId]

recordView = (params)->
  @Events.record "pageView", params
  Metrics.add _.extend({message:'load'}, params)
  _gaq.push ['_trackPageview'] if _gaq?

do ->
  Meteor.Router.add editRegex, (page, projectId, filePath, lineNumber, connectionId)->
    return unless MadEye.fileLoader
    Deps.nonreactive ->
      isHangout = false
      #TODO record type..edit/interview/scratch
      params = getQueryParams window.location.search
      if params.hangout
        Session.set "isHangout", true
        registerHangout projectId, params.hangoutUrl
        isHangout = true
      recordView {page, projectId, filePath, hangout: isHangout}
      Session.set 'projectId', projectId
      MadEye.editorState ?= new EditorState "editor"
      
    #Grab the (a?) scratch file if we are just going to the project
    unless filePath
      scratchFile = Files.findOne {scratch:true, projectId}
      filePath = scratchFile.path if scratchFile
    MadEye.fileLoader.loadPath = filePath
    #This editorFilePath probably isn't set yet, because we haven't flushed
    fileTree.open MadEye.fileLoader.editorFilePath, true

    unless page == "editImpressJS"
      return "edit"
    else
      return "editImpressJS"

  scratchPath = "SCRATCH.rb"

  Meteor.Router.add
    '/':  ->
      recordView page: "home"
      "home"
      
    '/get-started': ->
      recordView page: "get-started"
      "getStarted"

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
      project.name = 'interview' #Needed for mongoose schema
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

    '/createImpressJS': ->
      Meteor.http.post "http://localhost:4004/newImpressJSProject", (err, result)->
        data = JSON.parse result.content
        Meteor.Router.to "/editImpressJS/#{data['projectId']}/index.html"

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

    '/projectSelection': ->
      "projectSelection"

    '/unlinked-hangout': ->
      recordView page:'unlinked-hangout'
      Session.set "isHangout", true
      'unlinkedHangout'

    '*': ->
      console.log "Found missing url", window.location
      recordView page:'missing'
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

