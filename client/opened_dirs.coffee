OpenedDirs = new Meteor.Collection(null)

isDirOpen = (dirId) ->
  return OpenedDirs.findOne(fileId: dirId)?

openDir = (dirId) ->
  if !isDirOpen(dirId)
    OpenedDirs.insert(fileId: dirId)

closeDir = (dirId) ->
  if isDirOpen(dirId)
    OpenedDirs.remove(fileId: dirId)

toggleDir = (dirId) ->
  entry = OpenedDirs.findOne(fileId: dirId)
  console.log("Toggling for", dirId, ", found entry", entry)
  if entry
    OpenedDirs.remove(entry._id)
  else
    OpenedDirs.insert(fileId: dirId)

