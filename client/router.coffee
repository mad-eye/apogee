log = new Logger 'router'

RouteController.prototype.layoutTemplate = "layout"

Router.configure
  #layoutTemplate: "layout"
  loadingTemplate: "loading"


Router.onBeforeAction ->
  parseHangoutParams @params

Router.onBeforeAction ->
  viewData = {}
  for k, v of @params
    #TODO: The positional arguments have numeric keys, but this makes
    #things confused as to what type of object @params is
    viewData[k] = v
  viewData.page = @template
  recordView viewData

Router.onBeforeAction ->
  log.trace "Setting template to", @template
  Router.template = @template

Router.onBeforeAction ->
  if @params.filePath and @params.filePath[@params.filePath.length-1] == '/'
    @params.filePath = @params.filePath.substr 0, @params.filePath.length-1

Router.map ->
  @route 'edit',
    path: '/edit/:projectId/:filePath(*)?'
    notFoundTemplate: "missing"
    # The data and waitOn hooks allow us to send incorrect projectIds to a
    # missing page.
    data: ->
      Projects.findOne @params.projectId
    waitOn: ->
      handle = MadEye.subscriptions?.get('projects')
      #If the subscription hasn't been set yet, return a 'false' stub.
      handle ?= ready: -> false
      return handle
    onBeforeAction: ->
      beforeEdit this,
        projectId: @params.projectId
        filePath: @params.filePath
        lineNumber: @params.lineNumber
    
  @route 'file',
    template: 'wholeEditor'
    path: '/file/:projectId/:filePath(*)?'
    onBeforeAction: ->
      beforeEdit this,
        projectId: @params.projectId
        filePath: @params.filePath
        lineNumber: @params.lineNumber
        fileOnly: true
        zen: true

  @route 'terminal',
    template: 'terminal'
    path: '/terminal/:projectId'
    onBeforeAction: ->
      Session.set 'projectId', @params.projectId
      Session.set 'zen', true
      Session.set 'terminalOnly', true

  @route 'scratch',
    template: 'loading'
    onBeforeAction: ->
      Meteor.call 'registerProject',
        projectName: "New Project"
        scratch: true
      , (err, result) =>
        if err
          log.error 'Error creating scratch project', err
          #TODO: Direct to an error page?
        else
          log.debug 'Scratch project created, going to project.'
          Router.go 'edit', {projectId: result.projectId}

  @route 'impress.js',
    template: 'editImpressJS'
    onBeforeAction: ->
      Meteor.http.post "#{MadEye.azkabanUrl}/newImpressJSProject", (err, result)->
        if err
          log.error 'Error creating scratch project', err
          #TODO: Direct to an error page?
        else
          beforeEdit this,
            projectId: result.data['projectId']
            filePath: 'index.html'

  @route 'editImpressJS',
    path: '/editImpressJS/:projectId/:filePath(*)?'
    onBeforeAction: ->
      beforeEdit this,
        projectId: @params.projectId
        filePath: @params.filePath

  @route 'tests'

  @route 'facts'

  @route 'projectSelection',
    path: '/projectSelection'
    onBeforeAction: ->
      Session.set "isHangout", true

  #This is breaking IE, removing for now.
  #@route 'plans',
    #path: '/plans'
    #before: ->
      #unless Meteor.user() and Meteor.user().type != 'anonymous'
        #@render 'signinPage'
        #@stop()

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

beforeEdit = (router, {projectId, filePath, lineNumber, fileOnly, zen}) ->
  Session.set 'projectId', projectId
  #Grab the (a?) scratch file if we are just going to the project
  unless filePath
    scratchFile = Files.findOne {scratch:true, projectId}
    filePath = scratchFile.path if scratchFile
  MadEye.editorState ?= new EditorState "editor"
  MadEye.fileLoader.loadPath = filePath
  MadEye.fileLoader.lineNumber = lineNumber
  Session.set 'fileOnly', fileOnly
  Session.set 'zen', zen
  unless fileOnly
    MadEye.fileTree.open filePath, true
