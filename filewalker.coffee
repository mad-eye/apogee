#inspired by http://stackoverflow.com/questions/5827612/node-js-fs-readdir-recursive-directory-search

fs = undefined
if Meteor.is_server
  require = __meteor_bootstrap__.require;
  fs = require("fs");

walk = (dir, root, done)->
  results = []
  fs.readdir(dir, (err, list)->
    return done(err) if (err)
    pending = list.length
    return done(null, results) unless pending
    list.forEach((file)->
      file = dir + "/" + file
      fs.stat(file, (err,stat)->
        if (stat and stat.isDirectory())
          walk(file, root, (err,res)->
            results = results.concat(res)
            done(null, results) if (!--pending)
          )
        else
          results.push(
            name: file.replace(root, "")
            isDir: stat.isDirectory()
          )
          done(null, results) if (!--pending)
      )
    )
  )
