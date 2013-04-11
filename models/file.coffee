stripSlash = (path) ->
  if path.charAt(0) == '/'
    path = path.substring(1)
  if path.charAt(path.length-1) == '/'
    path = path.substring(0, path.length-1)
  return path

class File extends MeteorModel
 
Object.defineProperty File.prototype, 'filename',
  get: -> stripSlash(@path).split('/').pop()

Object.defineProperty File.prototype, 'depth',
  get: -> stripSlash(@path).split('/').length - 1 #don't count directory itself or leading /

Object.defineProperty File.prototype, 'parentPath',
  get: ->
    rightSlash = @path.lastIndexOf('/')
    if rightSlash > 0
      return @path.substring 0, rightSlash
    else
      return null

Object.defineProperty File.prototype, 'extension',
  get: ->
    tokens = @filename.split '.'
    if tokens.length > 1 then tokens.pop() else null

Object.defineProperty File.prototype, 'isBinary',
  get: -> /(bmp|gif|jpg|jpeg|png|psd|ai|ps|svg|pdf|exe|jar|dwg|dxf|7z|deb|gz|zip|dmg|iso|avi|mov|mp4|mpg|wmb|vob)$/i.test(@extension)

Object.defineProperty File.prototype, 'aceMode',
  get: ->
    extension = @extension?.toLowerCase()
    if extension
      Madeye.ACE_MODES[extension]
    else
      switch @filename
        when 'Makefile' then 'makefile'
        when 'Cakefile' then 'coffee'
        when 'Rakefile', 'Gemfile' then 'ruby'
        #TODO: Check for #!
        else null

Files = new Meteor.Collection 'files', transform: (doc) ->
  new File doc

File.prototype.collection = Files
