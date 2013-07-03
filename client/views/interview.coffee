
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

