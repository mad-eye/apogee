
Template.interviewIntro.rendered = ->
  $('#runTooltip').tooltip()

Template.interviewIntro.events
  'click #closeInterviewInstructions': (e) ->
    Session.set 'interviewInstructionsClosed', true
    windowSizeChanged()

  "click .hangout-link": (event) ->
    warnFirefoxHangout()

