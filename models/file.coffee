
stripSlash = (path) ->
  if path.charAt(0) == '/'
    path = path.substring(1)
  if path.charAt(path.length-1) == '/'
    path = path.substring(0, path.length-1)
  return path

class MadEye.File extends MadEye.Model
  constructor: (data) ->
    super data

  save: ->
    unless @path
      throw new Error "You must specify a path"
    if !@_id and Files.findOne {path: @path, projectId: @projectId}
      throw new Error "A file with that path already exists"
    super()
 

Object.defineProperty MadEye.File.prototype, 'isLoading',
  get: ->
    activeDirectory = ActiveDirectories.findOne {path: @path}
    unless activeDirectory
      return false
    else
      return not activeDirectory.loaded

Object.defineProperty MadEye.File.prototype, 'filename',
  get: -> stripSlash(@path).split('/').pop()

Object.defineProperty MadEye.File.prototype, 'depth',
  get: -> stripSlash(@path).split('/').length - 1 #don't count directory itself or leading /

Object.defineProperty MadEye.File.prototype, 'escapedPath',
  get: ->
    escapedValue = _.map(@path.split('/'), (segment) ->
      return encodeURIComponent(segment)
    ).join('/')
    
Object.defineProperty MadEye.File.prototype, 'parentPath',
  get: ->
    rightSlash = @path.lastIndexOf('/')
    if rightSlash > 0
      return @path.substring 0, rightSlash
    else
      return null

Object.defineProperty MadEye.File.prototype, 'extension',
  get: ->
    tokens = @filename.split '.'
    if tokens.length > 1 then tokens.pop() else null

Object.defineProperty MadEye.File.prototype, 'isBinary',
  get: ->
    MadEye.isBinaryExt @extension


@Files = new Meteor.Collection 'files', transform: (doc) ->
  new MadEye.File doc

MadEye.File.prototype.collection = @Files

if Meteor.isClient
  aceModes = ace.require('ace/ext/modelist')

  Object.defineProperty MadEye.File.prototype, 'aceMode',
    get: ->
      aceMode = aceModes.getModeForPath @filename
      #text is the default, which it will give if it doesn't recognize the filename.
      if aceMode.name == 'text' and @extension != 'txt'
        modeName = switch @filename
          when 'Rakefile', 'Gemfile', 'Guardfile', 'Vagrantfile', 'Assetfile'
            'ruby'
          #Others?
        aceMode = aceModes.modesByName[modeName]
      return aceMode?.name

  
