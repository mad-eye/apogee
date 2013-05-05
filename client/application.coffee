#for urls of the form /edit/PROJECT_ID/PATH_TO_FILE#LINE_NUMBER
#PATH_TO_FILE and LINE_NUMBER are optional
#editRegex = /\/edit\/([-0-9a-f]+)\/?([^#]*)#?([0-9]*)?/
#TODO should probably OR the line and session fields
@editRegex = /\/edit\/([-0-9a-f]+)\/?([^#]*)#?(?:L([0-9]*))?(?:S([0-9a-f-]*))?/
@interviewRegex = /\/interview(?:\/([-0-9a-f]+)(?:\/([^#]*)))?/
@transitoryIssues = null

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
  console.error "Registering hangout with url:", registerHangoutUrl
  Meteor.http.put registerHangoutUrl, {
      data: {hangoutUrl}
      headers: {'Content-Type':'application/json'}
      timeout: 5*1000
    }, (error,response) =>
      console.error "Registering hangout url failed.", error if error
      console.error "Regstering hangout response:", response


if Meteor.settings.public.googleAnalyticsId
  window._gaq = window._gaq || []
  _gaq.push ['_setAccount', Meteor.settings.public.googleAnalyticsId]

@_kmq = @_kmq || []

do ->
  recordView = (params)->
    event = _.extend {name: "pageView"}, params
    Deps.autorun (computation)->
      return if Meteor.loggingIn()
      _.extend event, {userId: Meteor.userId()}
      Events.insert event
      computation.stop()
    _gaq.push ['_trackPageview'] if _gaq?

  #TODO figure out how to eliminate all the duplicate recordView calls

  Meteor.Router.add editRegex, (projectId, filePath, lineNumber, connectionId)->
    isHangout = false
    params = getQueryParams window.location.search
    if params.hangout
      console.error "Found projectId", projectId
      Session.set "isHangout", true
      registerHangout projectId, params.hangoutUrl
      isHangout = true
    recordView {page: "editor", projectId: projectId, filePath: filePath, hangout: isHangout}
    Session.set 'projectId', projectId
    Metrics.add {message:'load', filePath, lineNumber, connectionId, isHangout}
    window.editorState ?= new EditorState "editor"
    editorState.setPath filePath
    editorState.setCursorDestination connectionId
    _kmq.push ['record', 'opened file', {projectId: projectId, filePath: filePath}]
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
      recordView()
      "tests"

    '/tos': ->
      recordView page: "tos"
      'tos'

    '/faq': ->
      recordView page: "faq"
      'faq'

    '/interview/:id/:filepath': (id, filepath)->
      if /hangout=true/.exec(document.location.href.split("?")[1])
        Session.set "isHangout", true
        isHangout = true

      recordView page: "interview"
      window.editorState ?= new EditorState "editor"
      Session.set "projectId", id
      editorState.setPath filepath
      "edit"

    '/interview/:id': (id)->
      if /hangout=true/.exec(document.location.href.split("?")[1])
        Session.set "isHangout", true
        isHangout = true

      recordView page: "interview"
      window.editorState ?= new EditorState "editor"
      Session.set "projectId", id
      "edit"

    '/interview': ->
      window.editorState ?= new EditorState "editor"
      #TODO add more info here..
      recordView page: "create interview"
      project = new Project()
      project.interview = true
      project.save()

      scratchPad = new MadEye.ScratchPad
      scratchPad.projectId = project._id
      scratchPad.path = scratchPath
      scratchPad.save()
      Meteor.setTimeout ->
        Meteor.Router.to "/interview/#{project._id}/#{scratchPath}"

    '/unlinked-hangout': ->
      recordView()
      Session.set "isHangout", true
      'unlinkedHangout'

    '*': ->
      recordView()
      "missing"

Deps.autorun ->
  projectId = Session.get "projectId"
  return unless projectId
  Meteor.subscribe "files", projectId
  Meteor.subscribe "projects", projectId
  Meteor.subscribe "projectStatuses", projectId
  Meteor.subscribe "scratchPads", projectId

Deps.autorun ->
  return if Meteor.loggingIn()
  Meteor.loginAnonymously() unless Meteor.user()

Meteor.startup ->
  transitoryIssues = new TransitoryIssues
  projectStatus = ProjectStatuses.findOne {sessionId:Session.get('sessionId')}
  Meteor.call "updateProjectStatusHeartbeat", Session.get("sessionId"), Session.get("projectId")


#COPIED FROM https://www.kissmetrics.com/settings
#maybe this could be replaced w/ a single script tag?
Meteor.startup ->
  _kmk = Meteor.settings.public.kissMetricsId;
  _kms = (u)->
    setTimeout ->
      d = document
      f = d.getElementsByTagName('script')[0]
      s = d.createElement('script')
      s.type = 'text/javascript'
      s.async = true
      s.src = u
      f.parentNode.insertBefore(s, f)
    , 1
  _kms('//i.kissmetrics.com/i.js');
  _kms('//doug1izaerwt3.cloudfront.net/' + _kmk + '.1.js');

