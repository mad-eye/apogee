log = new Logger 'azkaban'

MadEye.azkabanUrl = Meteor.settings.public.azkabanUrl
fileUrl = (projectId, fileId) -> "#{MadEye.azkabanUrl}/project/#{projectId}/file/#{fileId}"


MadEye.Azkaban =
  #@returns: {fileId:, contents:, warning:}
  requestStaticFile: (projectId, fileId) ->
    log.debug "Saving static file #{fileId}"
    response = Meteor.http.get fileUrl(projectId, fileId), {
      data: {static: true}
      headers: {'Content-Type':'application/json'}
      timeout: 5*1000
    }
    checksum = response.data.checksum
    Files.update fileId, {$set: {lastOpened: Date.now(), fsChecksum:checksum, loadChecksum:checksum}}
    return {fileId}

  #@returns: nothing
  saveStaticFile: (projectId, fileId, contents) ->
    log.debug "Saving static file #{fileId}"
    response = Meteor.http.put fileUrl(projectId, fileId), {
      data: {contents, static: true}
      headers: {'Content-Type':'application/json'}
      timeout: 5*1000
    }
    checksum = MadEye.crc32 contents
    Files.update fileId, {$set: {fsChecksum:checksum, loadChecksum:checksum}}

  revertStaticFile: (projectId, fileId) ->
    log.debug "Reverting static file #{fileId}"
    response = Meteor.http.get fileUrl(projectId, fileId), {
      data: {static: true}
      params: {reset: true}
      headers: {'Content-Type':'application/json'}
      timeout: 5*1000
    }
    checksum = response.checksum
    Files.update fileId, {$set: {fsChecksum:checksum, loadChecksum:checksum}}
    return {fileId}
