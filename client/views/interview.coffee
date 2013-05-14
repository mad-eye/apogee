Template.interview.helpers
  projectId: ->
    Projects.findOne()?._id

  scratchPads: ->
    Files.find(scratch: true)

  selected: ->
    file = Files.findOne editorState.fileId
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

@warnFirefoxHangout = ->
  if "Firefox" == BrowserDetect.browser
    confirm "Firefox currently has performance issues in MadEye Hangouts.  For best experience, use Chrome or Safari.  Thanks, and we'll fix this soon!"
  

Template.interview.rendered = ->
  return if Dropzone.forElement "#dropzone"
  $("#dropzone").dropzone
    paramName: "file"
    accept: (dropfile, done)->
      file = new MadEye.File
      file.scratch = true
      file.path = dropfile.name
      file.projectId = Session.get "projectId"
      try
        file.save()
        @options.url = "#{Meteor.settings.public.azkabanUrl}/file-upload/#{file._id}"
        done()
      catch e
        alert e.message
        done(e.message)
    url: "bogus" #can't initialize a dropzone w/o a url, overwritten in accept function above

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

