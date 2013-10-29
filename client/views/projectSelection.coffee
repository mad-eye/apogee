Template.projectSelection.events
  "click #loadProjectButton": (e)->
    userInput = $("#madeyeUrl").val()
    projectId = /\/edit\/([-0-9a-zA-Z]*)/.exec(userInput)[1]
    Router.go "/edit/#{projectId}?hangout=true"
    return false
