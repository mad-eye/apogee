Template.editImpressJS.events
  "click #fullPresentationLink": ->
    window.open $("#fullPresentationLink").attr("href")
    return false

Meteor.startup ->
  Deps.autorun ->
    unless Session.get "lastRefreshed"
      Session.set "lastRefreshed", 0
    project = Projects.findOne Session.get("projectId")
    if project and project.impressJS and project.lastUpdated > Session.get "lastRefreshed"
      Session.set "lastRefreshed", Date.now()
      $("#presentationPreview")[0].contentDocument.location.reload()
