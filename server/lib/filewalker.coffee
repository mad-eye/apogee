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

walk = (dir, root, filter, done)->
  results = []
  fs.readdir(dir, (err, list)->
    return done(err) if (err)
    if filter
      list = _.filter(list, filter)
    pending = list.length
    return done(null, results) unless pending
    list.forEach((file)->
      file = dir + "/" + file
      fs.stat(file, (err,stat)->
        results.push(
          path: file.replace(root, "")
          isDir: stat.isDirectory()
          parentPath: dir.replace(root, "")
        )
        if (stat and stat.isDirectory())
          walk(file, root, filter, (err,res)->
            results = results.concat(res)
            done(null, results) if (!--pending)
          )
        else
          done(null, results) if (!--pending)
      )
    )
  )
