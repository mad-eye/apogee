log = new MadEye.Logger 'router'


Router.configure
  layout: "layout"
  notFoundTemplate: "notFound"
  loadingTemplate: "loading"
  before: [
    ->
      @query = getQueryParams window.location.search
  , ->
    if @query.hangout
      Session.set "isHangout", true
      if @params.projectId and @query.hangoutUrl
        log.debug "Registering hangoutUrl #{@query.hangoutUrl} for project #{@params.projectId}"
        registerHangout projectId, @query.hangoutUrl
  , ->
    viewData = _.clone @query
    for k,v of @params
      viewData[k] = v
    viewData.page = @template
    recordView viewData
  , ->
    Router.template = @template
  ]
  after: ->
    @query = {}

Router.map ->
  @route 'home', path: '/'
  @route 'getStarted', path: '/get-started'
  @route 'edit',
    path: '/edit/:projectId/:filePath(*)?'
    before: ->
      beforeEdit this, @params.projectId, @params.filePath
    
  @route 'scratch',
    template: 'edit'
    before: ->
      Meteor.call 'registerProject',
        projectName: "New Project"
        scratch: true
      , (err, result) ->
        if err
          log.error 'Error creating scratch project', err
          #TODO: Direct to an error page?
        else
          beforeEdit this, result.projectId

  @route 'impress.js',
    template: 'editImpressJS'
    before: ->
      Meteor.http.post "#{MadEye.azkabanUrl}/newImpressJSProject", (err, result)->
        if err
          log.error 'Error creating scratch project', err
          #TODO: Direct to an error page?
        else
          beforeEdit this, result.data['projectId'], 'index.html'

  @route 'editImpressJS',
    path: '/editImpressJS/:projectId/:filePath(*)?'
    before: ->
      beforeEdit this, @params.projectId, @params.filePath

  @route 'tests'
  @route 'tos'
  @route 'faq'
  @route 'projectSelection'
  @route 'unlinkedHangout',
    path: '/unlinked-hangout'
    before: ->
      Session.set "isHangout", true

  @route 'missing', path: '*'

## Set up reactive Router.template var
_template = null
_templateDep = new Deps.Dependency
Object.defineProperty Router, 'template',
  get: ->
    _templateDep.depend()
    return _template

  set: (template) ->
    return if template == _template
    _template = template
    _templateDep.changed()

## Analytics and tracking
if Meteor.settings.public.googleAnalyticsId
  window._gaq = window._gaq || []
  _gaq.push ['_setAccount', Meteor.settings.public.googleAnalyticsId]

recordView = (params)->
  @Events.record "pageView", params
  #Metrics.add _.extend({message:'load'}, params)
  log.debug 'load', params
  _gaq.push ['_trackPageview'] if _gaq?


## Helper fns

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

beforeEdit = (router, projectId, filePath) ->
  Session.set 'projectId', projectId
  #Grab the (a?) scratch file if we are just going to the project
  unless filePath
    scratchFile = Files.findOne {scratch:true, projectId}
    filePath = scratchFile.path if scratchFile
  MadEye.editorState ?= new EditorState "editor"
  MadEye.fileLoader.loadPath = filePath
  #This editorFilePath probably isn't set yet, because we haven't flushed
  MadEye.fileTree.open MadEye.fileLoader.editorFilePath, true


registerHangout = (projectId, hangoutUrl) ->
  return unless hangoutUrl
  registerHangoutUrl = MadEye.azkabanUrl + "/hangout/" + projectId
  Meteor.http.put registerHangoutUrl, {
      data: {hangoutUrl}
      headers: {'Content-Type':'application/json'}
      timeout: 5*1000
    }, (error,response) =>
      log.error "Registering hangout url failed.", error if error

