Meteor.startup ->
  describe 'FileLoader', ->
    File = MadEye.File
    assert = chai.assert
    fileLoader = null
    file1 = file2 = dir1 = null

    before ->
      file1 = new File path: 'file1', isDir: false
      file1.save()
      dir1 = new File path: 'dir1', isDir: true
      dir1.save()
      file2 = new File path: 'dir1/file2', isDir: false
      file2.save()

    beforeEach ->
      console.log "FileLoader:", FileLoader
      fileLoader = new FileLoader

    checkOutput = (fileLoader, editorFile, selectedFile) ->
      selectedFile ?= editorFile
      assert.equal fileLoader.selectedFileId, selectedFile?._id
      assert.equal fileLoader.selectedFilePath, selectedFile?.path
      assert.equal fileLoader.editorFileId, editorFile?._id
      assert.equal fileLoader.editorFilePath, editorFile?.path

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


  ###
  More Tests:

  load file then dir: dir selected, file editor
  loadPath to non-existent file, save file: all set
  loadPath to non-existent dir, save dir: just selected set

  load link: selected, not editor, alert ok
  load binary: selected, not editor, alert ok
  ###

