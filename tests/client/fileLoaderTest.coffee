Meteor.startup ->
  describe 'FileLoader', ->
    File = MadEye.File
    assert = chai.assert
    fileLoader = null
    file1 = file2 = dir1 = link = image = null

    before ->
      file1 = new File path: 'file1', isDir: false
      file1.save()
      dir1 = new File path: 'dir1', isDir: true
      dir1.save()
      file2 = new File path: 'dir1/file2', isDir: false
      file2.save()
      link = new File path: 'link', isDir: false, isLink: true
      link.save()
      image = new File path: 'cat.jpg', isDir: false
      image.save()

    beforeEach ->
      fileLoader = new FileLoader()

    checkOutput = (fileLoader, editorFile, selectedFile, alert) ->
      selectedFile ?= editorFile
      assert.equal fileLoader.selectedFileId, selectedFile?._id
      assert.equal fileLoader.selectedFilePath, selectedFile?.path
      assert.equal fileLoader.editorFileId, editorFile?._id
      assert.equal fileLoader.editorFilePath, editorFile?.path
      if alert
        assert.ok fileLoader.alert
        assert.equal fileLoader.alert.level, alert.level
        assert.equal fileLoader.alert.message, alert.message
      else
        assert.ok !fileLoader.alert?

    it 'should set output correctly on file loadPath', ->
      fileLoader.loadPath = file1.path
      Deps.flush()
      checkOutput fileLoader, file1

    it 'should set output correctly on file loadId', ->
      fileLoader.loadId = file1._id
      Deps.flush()
      checkOutput fileLoader, file1

    it 'should set output correctly on dir loadPath', ->
      fileLoader.loadPath = dir1.path
      Deps.flush()
      checkOutput fileLoader, null, dir1

    it 'should set output correctly on dir loadId', ->
      fileLoader.loadId = dir1._id
      Deps.flush()
      checkOutput fileLoader, null, dir1

    it 'should not overwrite editorFile on dir load', ->
      fileLoader.loadId = file1._id
      Deps.flush()
      fileLoader.loadId = dir1._id
      Deps.flush()
      checkOutput fileLoader, file1, dir1

    it 'should wait and a file that hasnt been saved', ->
      newFile = new File path: 'newFile', isDir: false
      fileLoader.loadPath = newFile.path
      Deps.flush()
      checkOutput fileLoader, null, null
      newFile.save()
      Deps.flush()
      checkOutput fileLoader, newFile

    it 'should wait and a dir that hasnt been saved', ->
      newDir = new File path: 'newDir', isDir: true
      fileLoader.loadPath = newDir.path
      Deps.flush()
      checkOutput fileLoader, null, null
      newDir.save()
      Deps.flush()
      checkOutput fileLoader, null, newDir

    it 'should set output correctly on link loadId', ->
      fileLoader.loadId = link._id
      Deps.flush()
      checkOutput fileLoader, null, link,
        level: 'error'
        message: link.path

    it 'should set output correctly on binary loadId', ->
      fileLoader.loadId = image._id
      Deps.flush()
      checkOutput fileLoader, null, image,
        level: 'error'
        message: image.path

