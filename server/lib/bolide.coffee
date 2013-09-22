MAX_LENGTH = 16777216 #2^24, a large number of chars

#TODO: Merge this with client/lib/urls.coffee somehow
MadEye.bolideUrl = Meteor.settings.public.bolideUrl
fileUrl = (fileId) -> "#{MadEye.bolideUrl}/doc/#{fileId}"

MadEye.Bolide =
  getShareContents: (fileId, callback) ->
    throw new Error "fileId required for getShareContents" unless fileId
    options =
      timeout: 10*1000
    results = Meteor.http.get fileUrl(fileId), options
    console.log "File #{fileId} results:", results
    #Meteor downcases the header names, for some reason.
    return {
      version: results.headers['x-ot-version']
      type: results.headers['x-ot-type']
      contents: results.content
    }

  setShareContents: (fileId, contents, version=0) ->
    throw new Error "fileId required for setShareContents" unless fileId
    throw new Error "Contents cannot be null for file #{fileId}" unless contents?
    ops = []
    ops.push {d:MAX_LENGTH} #delete operation, clear contents if any
    ops.push contents if contents #insert operation; can't insert ''
    options =
      params: {v:version} #goes in query string because of data
      data: ops
      timeout: 10*1000
    Meteor.http.post fileUrl(fileId), options



