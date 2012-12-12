describe "FileTree", ->

  fakeCollection = [{ "isDir" : false, "path" : "/xylophone/root_file", "projectId" : "ec583c52-67a8-4753-8e37-4c6b813ed344", "_id" : "0e099d16-e63a-4e72-87e0-679ef73928f3" },
    { "isDir" : true, "path" : "/xylophone/root_folder", "projectId" : "ec583c52-67a8-4753-8e37-4c6b813ed344", "_id" : "00e29227-b7ab-4637-8823-51003a830aa8" },
    { "isDir" : false, "path" : "/xylophone/root_folder/sub_file", "projectId" : "ec583c52-67a8-4753-8e37-4c6b813ed344", "_id" : "179470f1-bd2d-4a39-a147-db4ccb1bad06" }]

  fileTree = new FileTree(fakeCollection)
  root_folder = fileTree.findByPath "/xylophone/root_folder"
  sub_file = fileTree.findByPath "/xylophone/root_folder"

  it "starts with root elements visible, but everything else hidden", ->
    chai.assert.isTrue fileTree.isVisible {path: "/xylophone/root_file"}
    chai.assert.isTrue fileTree.isVisible {path: "/xylophone/root_folder"}
    chai.assert.isFalse fileTree.isVisible {path: "/xylophone/root_folder/sub_file"}

  it "starts with closed folders", ->
    chai.assert.isFalse root_folder.isOpen()
    
  it "opens closed folders when they are selected", ->
    root_folder.select()
    chai.assert.isTrue root_folder.isSelected()
    chai.assert.isTrue root_folder.isOpen()

  it "shows children of open folders", ->
    chai.assert.isTrue fileTree.isVisible {path: "/xylophone/root_folder/sub_file"}

  it "closes an open folder when it is selected", ->
    root_folder.select()
    chai.assert.isTrue root_folder.isSelected()
    chai.assert.isFalse root_folder.isOpen()        