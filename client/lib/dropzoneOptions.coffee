Dropzone.options.myAwesomeDropzone =
  accept: (file, done)->
    pad = new MadEye.ScratchPad
    pad.path = file.name
    pad.projectId = Session.get "projectId"
    pad.save()

    #set hidden element here with the form element so id can be passed to azkaban

    #TODO create new item in collection here..
    done()
  createImageThumbnails: false

