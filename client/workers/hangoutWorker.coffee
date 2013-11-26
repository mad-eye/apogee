@parseHangoutParams = (params={}) ->
  Session.set "isHangout", true if params.hangout
  Session.set "hangoutUrl", params.hangoutUrl if params.hangoutUrl
  Session.set "hangoutId", params.hangoutId if params.hangoutId
  

Meteor.startup ->
  Deps.autorun ->
    hangoutUrl = Session.get 'hangoutUrl'
    return unless hangoutUrl
    project = getProject()
    return unless project
    unless project.hangoutUrl
      #We're the first; set the hangoutUrl for other people.
      project.update {hangoutUrl}
    else if hangoutUrl == project.hangoutUrl
      #all is ok
      Session.set 'mismatchedHangout', false
    else
      #Our hangoutUrl is not the standard.
      Session.set 'mismatchedHangout', true


