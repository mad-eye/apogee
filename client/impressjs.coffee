Template.editImpressJS.events
  "click #fullPresentationLink": ->
    window.open $("#fullPresentationLink").attr("href")
    return false
