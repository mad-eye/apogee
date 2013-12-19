Meteor.startup ->
  if Meteor.settings?.public?.jsCssPrefix
    WebAppInternals.setBundledJsCssPrefix Meteor.settings.public.jsCssPrefix

