Template.projectSelection.events
  "click #loadProjectButton": (e)->
    userInput = $("#madeyeUrl").val()
    projectId = /([-0-9a-f]*)\s*$/.exec(userInput)[1]
    Meteor.Router.to "/edit/#{projectId}?hangout=true"
    return false
