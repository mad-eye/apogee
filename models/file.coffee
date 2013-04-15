stripSlash = (path) ->
  if path.charAt(0) == '/'
    path = path.substring(1)
  if path.charAt(path.length-1) == '/'
    path = path.substring(0, path.length-1)
  return path

class MadEye.File extends MadEye.Model
  constructor: (data) ->
    super data
 
Object.defineProperty MadEye.File.prototype, 'filename',
  get: -> stripSlash(@path).split('/').pop()

Object.defineProperty MadEye.File.prototype, 'depth',
  get: -> stripSlash(@path).split('/').length - 1 #don't count directory itself or leading /

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
  get: -> /(bmp|gif|jpg|jpeg|png|psd|ai|ps|svg|pdf|exe|jar|dwg|dxf|7z|deb|gz|zip|dmg|iso|avi|mov|mp4|mpg|wmb|vob)$/i.test(@extension)

Object.defineProperty MadEye.File.prototype, 'aceMode',
  get: ->
    extension = @extension?.toLowerCase()
    if extension
      MadEye.ACE_MODES[extension]
    else
      switch @filename
        when 'Makefile' then 'makefile'
        when 'Cakefile' then 'coffee'
        when 'Rakefile', 'Gemfile' then 'ruby'
        else null

@Files = new Meteor.Collection 'files', transform: (doc) ->
  new MadEye.File doc

MadEye.File.prototype.collection = @Files
