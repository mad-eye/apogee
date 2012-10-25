constructFileTree = (files) ->
  console.log "Constructing file tree"
  files.sort (f1, f2) ->
    return f1.parents.length - f2.parents.length if f1.parents.length != f2.parents.length
    for i in [0..f1.parents.length]
      return f1.parents[i] < f2.parents[i] ? 1 : -1 if f1.parents[i] != f2.parents[i]
    return f1.name < f2.name ? 1 : -1

  fileTree = []
  fileTreeMap = {}
  filePrototype =
    parent_path: -> @parents.join "/"

  files.forEach (file) ->
    #XXX should probably not have to do this for every file object..
    _.extend(file, filePrototype)
    file.children ?= []
    #console.log("Storing file", file.path)
    fileTreeMap[file.path] = file
    parent = fileTreeMap[file.parent_path()]
    #console.log("Found parent for path " + file.parent_path() + ":", parent)
    if parent
      parent.children.push(file)
    else
      fileTree.push(file)
    
  return fileTree


