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
    hangoutId = Session.get 'hangoutId'
    unless project.hangoutUrl
      #We're the first; set the hangoutUrl for other people.
      project.update {hangoutUrl, hangoutId}
    #XXX: should this be hangoutId?
    else if hangoutUrl == project.hangoutUrl
      #all is ok
      Session.set 'mismatchedHangout', false
    else #hangoutUrl != project.hangoutUrl
      #We are in the wrong hangout
      Session.set 'mismatchedHangout', true
      #TODO: Handle this better; move them to the right hangout?
      #XXX: if we move them, make sure hangoutUrl is not stale
