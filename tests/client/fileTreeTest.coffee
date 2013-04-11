describe "FileTree", ->
  fileTree = null
  assert = chai.assert

  before ->
    fileTree = new FileTree

  describe 'open/isOpen', ->
    it 'should default to closed', ->
      assert.ok !fileTree.isOpen 'random/path'

    it 'should record an open path', ->
      path = 'a/path/dir'
      fileTree.open path
      assert.isTrue fileTree.isOpen path
      assert.ok !fileTree.isOpen 'a/path'
      assert.ok !fileTree.isOpen 'a'

    it 'should open parents when recusive', ->
      path = 'deeply/nested/path'
      fileTree.open path, true
      assert.isTrue fileTree.isOpen path
      assert.isTrue fileTree.isOpen 'deeply/nested'
      assert.isTrue fileTree.isOpen 'deeply'

    it 'should open a closed path', ->
      path = 'open4'
      fileTree.close path
      fileTree.open path
      assert.isTrue fileTree.isOpen path

    it 'should be reactive', ->
      openNow = null
      Deps.autorun ->
        openNow = fileTree.isOpen('weeble') == true
      fileTree.open 'weeble'
      Deps.flush()
      assert.isTrue openNow

  describe 'close', ->
    it 'should close a path', ->
      path = 'closeme'
      fileTree.open path
      fileTree.close path
      assert.isFalse fileTree.isOpen path

    it 'should be reactive', ->
      path = 'moreclose/today'
      openNow = null
      fileTree.open path
      Deps.autorun ->
        openNow = fileTree.isOpen(path) == true
      fileTree.close path
      Deps.flush()
      assert.isFalse openNow

  describe 'toggle', ->
    it 'should open an unknown path', ->
      path = 'toggle1'
      fileTree.toggle path
      assert.isTrue fileTree.isOpen path

    it 'should open a closed path', ->
      path = 'toggle2'
      fileTree.close path
      fileTree.toggle path
      assert.isTrue fileTree.isOpen path

    it 'should close an opened path', ->
      path = 'toggle3'
      fileTree.open path
      fileTree.toggle path
      assert.isFalse fileTree.isOpen path

    it 'should be reactive', ->
      path = 'toggle4'
      openNow = null
      Deps.autorun ->
        openNow = fileTree.isOpen(path) == true
      fileTree.toggle path
      Deps.flush()
      assert.isTrue fileTree.isOpen path
      fileTree.toggle path
      Deps.flush()
      assert.isFalse fileTree.isOpen path

  describe 'isVisible', ->
    path = 'a2/b2/c2'
    ppath = 'a2/b2'
    gppath = 'a2'

    beforeEach ->
      fileTree = new FileTree

    it "should be visible if it's top level", ->
      assert.isTrue fileTree.isVisible gppath

    it "should be visible if it has one open parent", ->
      fileTree.open gppath
      assert.isTrue fileTree.isVisible ppath
    
    it "should not be visible if it has one closed parent", ->
      fileTree.close gppath
      assert.isFalse fileTree.isVisible ppath
    
    it "should be visible if it has two open parents", ->
      fileTree.open gppath
      fileTree.open ppath
      assert.isTrue fileTree.isVisible path

    it "should not be visible if it has closed immediate parent", ->
      fileTree.open gppath
      fileTree.close ppath
      assert.isFalse fileTree.isVisible path

    it "should not be visible if it has closed distant parent", ->
      fileTree.close gppath
      fileTree.open ppath
      assert.isFalse fileTree.isVisible path

    it "should not be visible if it has two closed parents", ->
      fileTree.close gppath
      fileTree.open ppath
      assert.isFalse fileTree.isVisible path

    #This is a bit elaborate, maybe should break up?
    it "should be reactive to grand-parent's open state", ->
      visNow = null
      Deps.autorun ->
        visNow = fileTree.isVisible path
      fileTree.open gppath
      fileTree.open ppath
      Deps.flush()
      assert.isTrue visNow
      fileTree.close gppath
      Deps.flush()
      assert.isFalse visNow
      fileTree.open gppath
      Deps.flush()
      assert.isTrue visNow

    it "should be reactive to parent's open state", ->
      visNow = null
      Deps.autorun ->
        visNow = fileTree.isVisible path
      fileTree.open gppath
      fileTree.open ppath
      Deps.flush()
      assert.isTrue visNow
      fileTree.close ppath
      Deps.flush()
      assert.isFalse visNow
      fileTree.open ppath
      Deps.flush()
      assert.isTrue visNow

    it "should be reactive to complex chain of openings", ->
      visNow = null
      Deps.autorun ->
        visNow = fileTree.isVisible path
      fileTree.open gppath
      Deps.flush()
      assert.ok !visNow
      fileTree.open ppath
      Deps.flush()
      assert.isTrue visNow
      fileTree.close gppath
      Deps.flush()
      assert.isFalse visNow
      fileTree.open gppath
      Deps.flush()
      assert.isTrue visNow


      

###
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

  describe "visibleParent", ->
    projectId = Meteor.uuid()
    dir1 = dir2 = file1 = null
    before ->
      dir1 = Files.create {path:'dir1', isDir:true, projectId}
      dir2 = Files.create {path:'dir1/dir2', isDir:true, projectId}
      file1 = Files.create {path:'dir1/dir2/file1', isDir:false, projectId}

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

###
