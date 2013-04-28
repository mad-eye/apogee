Dropzone.options.myAwesomeDropzone =
  accept: (file, done)->
    pad = new MadEye.ScratchPad
    pad.path = file.name
    pad.projectId = Session.get "projectId"
    pad.save()
    #TODO create new item in collection here..
    done()
  createImageThumbnails: false

