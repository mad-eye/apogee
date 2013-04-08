describe "FileTree", ->
  assert = chai.assert

  fakeCollection = [{ "isDir" : false, "path" : "/xylophone/root_file", "projectId" : "ec583c52-67a8-4753-8e37-4c6b813ed344", "_id" : "0e099d16-e63a-4e72-87e0-679ef73928f3" },
    { "isDir" : true, "path" : "/xylophone/root_folder", "projectId" : "ec583c52-67a8-4753-8e37-4c6b813ed344", "_id" : "00e29227-b7ab-4637-8823-51003a830aa8" },
    { "isDir" : false, "path" : "/xylophone/root_folder/sub_file", "projectId" : "ec583c52-67a8-4753-8e37-4c6b813ed344", "_id" : "179470f1-bd2d-4a39-a147-db4ccb1bad06" }]

  fileTree = new FileTree(fakeCollection)
  root_folder = fileTree.findByPath "/xylophone/root_folder"
  root_file = fileTree.findByPath "/xylophone/root_file"
  sub_file = fileTree.findByPath "/xylophone/root_folder/sub_file"

  it "starts with root elements visible, but everything else hidden", ->
    assert.isTrue fileTree.isVisible root_file
    assert.isTrue fileTree.isVisible root_folder
    assert.isFalse fileTree.isVisible sub_file

  it "starts with closed folders", ->
    assert.isFalse root_folder.isOpen()
    
  it "opens closed folders when they are selected", ->
    root_folder.select()
    assert.isTrue root_folder.isSelected()
    assert.isTrue root_folder.isOpen()

  it "shows children of open folders", ->
    assert.isTrue fileTree.isVisible {path: "/xylophone/root_folder/sub_file"}

  it "closes an open folder when it is selected", ->
    root_folder.select()
    assert.isTrue root_folder.isSelected()
    assert.isFalse root_folder.isOpen()

describe "File", ->
  describe "visibleParent", ->
    projectId = Meteor.uuid()
    dir1 = dir2 = file1 = null
    before ->
      dir1 = Files.collection.insert {path:'dir1', isDir:true, projectId}
      dir1 = Files.findOne dir1._id
      dir2 = Files.collection.insert {path:'dir1/dir2', isDir:true, projectId}
      dir2 = Files.findOne dir2._id
      file1 = Files.collection.insert {path:'dir1/dir2/file1', isDir:false, projectId}
      file1 = Files.findOne file1._id


      fileTree = new FileTree(Files.find {projectId} )

    it 'should give file when all parents are visible', ->
      dir1.open()
      dir2.open()
      assert.deepEqual file1.visibleParent(), file1

    it 'should give dir2 when dir2 is closed', ->
      dir1.open()
      dir2.close()
      assert.deepEqual file1.visibleParent(), dir2

    it 'should give dir1 when dir1 is closed', ->
      dir1.close()
      dir2.open()
      assert.deepEqual file1.visibleParent(), dir1

    it 'should give dir1 when both dirs are closed', ->
      dir1.close()
      dir2.close()
      assert.deepEqual file1.visibleParent(), dir1

