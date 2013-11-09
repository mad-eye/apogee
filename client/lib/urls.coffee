#HACK port indicates a lack of proxy
if document.location.port
  MadEye.azkabanUrl = Meteor.settings.public.azkabanUrl
  MadEye.bolideUrl = Meteor.settings.public.bolideUrl
  MadEye.makeTunnelUrl = (remotePort) ->
    "http://#{Meteor.settings.public.tunnelHost}:#{remotePort}"
  MadEye.makeTunnelResource = (remotePort) ->
    null
else
  madeyeUrl = "#{document.location.protocol}//#{document.location.hostname}"
  MadEye.azkabanUrl = "#{madeyeUrl}/api"
  MadEye.bolideUrl = "#{madeyeUrl}/ot"
  MadEye.makeTunnelUrl = (remotePort) ->
    madeyeUrl
  MadEye.makeTunnelResource = (remotePort) ->
    "/tunnel/#{remotePort}/socket.io"
