#Exposed for tests.
@newFileLoader = ->
  new ReactiveMachine
    properties:
      loadPath:
        set: '_loadPath'
      loadId:
        set: '_loadId'
      selectedFileId:
        get: '_selectedFileId'
      selectedFilePath:
        get: '_selectedFilePath'
      editorFileId:
        get: '_editorFileId'
      editorFilePath:
        get: '_editorFilePath'
      alert:
        get: '_alert'
        set: '_alert'
    sentries: [
      (computation) ->
        @depend 'loadId'
        @depend 'loadPath'
        if @_loadPath
          file = Files.findOne path:@_loadPath
        if @_loadId
          file = Files.findOne @_loadId unless file
        return unless file
        @_loadId = @_loadPath = null
        @_selectedFileId = file._id
        @changed 'selectedFileId'
        @_selectedFilePath = file.path
        @changed 'selectedFilePath'

        if file.isDir
          return
        if file.isLink
          @alert =
            level: "error"
            title: "Unable to load symbolic link"
            message: file.path
          return
        if file.isBinary
          @alert =
            level: "error"
            title: "Unable to load binary file"
            message: file.path
          return

        #Else, this is a normal file. 
        @_editorFileId = file._id
        @changed 'editorFileId'
        @_editorFilePath = file.path
        @changed 'editorFilePath'
    ]

MadEye.fileLoader = newFileLoader()

