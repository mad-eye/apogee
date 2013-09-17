#HACK port indicates a lack of proxy
if document.location.port
  MadEye.azkabanUrl = Meteor.settings.public.azkabanUrl
  MadEye.bolideUrl = Meteor.settings.public.bolideUrl
else
  madeyeUrl = "#{document.location.protocol}//#{document.location.hostname}"
  MadEye.azkabanUrl = "#{madeyeUrl}/api"
  MadEye.bolideUrl = "#{madeyeUrl}/ot"
