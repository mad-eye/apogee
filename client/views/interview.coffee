Template.interview.helpers
  scratchPads: ->
    #Files.find(scratch: true)
    Files.find {}, {sort: {orderingPath:1} }

  selected: ->
    file = Files.findOne MadEye.editorState.fileId
    if file?.path == @path
      "selected"
    else
      "unselected"

  #XXX TODO copied w/ shame from fileTreeView.coffee
  usersInFile: (file)->
    projectId = Session.get "projectId"
    sessionIds = fileTree.getSessionsInFile file.path
    return unless sessionIds
    users = null
    Deps.nonreactive ->
      users = ProjectStatuses.find(sessionId: {$in: sessionIds}).map (status) ->
        {img: "/images/#{USER_ICONS[status.iconId]}"}
    return users


#XXX TODO: Copied from fileTreeView.coffee
Template.interview.events
  "click li": (event)->
    projectId = Session.get "projectId"
    filename = event.currentTarget.id
    Meteor.Router.to "/interview/#{projectId}/#{filename}"

  "click #addFileButton": (event)->
    filename = prompt "Enter a filename"
    return unless filename?
    file = new MadEye.File
    file.scratch = true
    projectId = Session.get "projectId"
    file.projectId = projectId
    file.path = filename
    try
      file.save()
      Meteor.Router.to "/interview/#{projectId}/#{filename}"
    catch e
      alert e.message

  "click .hangout-link": (event) ->
    warnFirefoxHangout()
    #Page.js tries to handle this, but gets the port wrong.
    event.stopPropagation()
    window.location = event.target.href

@warnFirefoxHangout = ->
  if "Firefox" == BrowserDetect.browser
    confirm "Firefox currently has performance issues in MadEye Hangouts.  For best experience, use Chrome or Safari.  Thanks, and we'll fix this soon!"
  

Template.interviewIntro.rendered = ->
  $('#runTooltip').tooltip()

Template.interviewIntro.events
  'click #closeInterviewInstructions': (e) ->
    Session.set 'interviewInstructionsClosed', true
    Meteor.setTimeout ->
      resizeEditor()
    , 0

  "click .hangout-link": (event) ->
    warnFirefoxHangout()

