#inspired by http://stackoverflow.com/questions/5827612/node-js-fs-readdir-recursive-directory-search
# TODO: Clean up using https://github.com/possibilities/meteor-node-modules

fs = undefined
if Meteor.is_server
  require = __meteor_bootstrap__.require
  fs = require("fs")

stripSlash = (str) ->
  return str unless str?
  if str.charAt(0) == '/'
    str = str.substring(1,str.length)
  if str.charAt(str.length) == '/'
    str = str.substring(0,str.length-1)
  return str

cleanPath = (str, root) ->
  str = str.replace(root, "")
  return str

walk = (dir, root, done)->
  results = []
  fs.readdir(dir, (err, list)->
    return done(err) if (err)
    pending = list.length
    return done(null, results) unless pending
    list.forEach((file)->
      file = dir + "/" + file
      fs.stat(file, (err,stat)->
        results.push(
          path: cleanPath(file)
          isDir: stat.isDirectory()
          parentPath: cleanPath(dir)
        )
        if (stat and stat.isDirectory())
          walk(file, root, (err,res)->
            results = results.concat(res)
            done(null, results) if (!--pending)
          )
        else
          done(null, results) if (!--pending)
      )
    )
  )
