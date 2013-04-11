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

  describe 'select', ->
    #toSpy = sinon.spy()
    called = null
    calledArgs = null
    toSpy = () ->
      called = true
      calledArgs = _.toArray arguments


    oldTo = null
    file = dir = null
    projectId = Meteor.uuid()

    before ->
      oldTo = Meteor.Router.to
      Meteor.Router.to = toSpy
      file = File.create path:'a4/b4/file.txt', isDir:false, projectId:projectId
      dir = File.create path:'a4/b4', isDir:true, projectId:projectId

    beforeEach ->
      fileTree = new FileTree
      called = null
      calledArgs = null

    after ->
      Meteor.Router.to = oldTo

    it 'should set selectedFileId for file and navigate', ->
      fileTree.select file
      assert.equal Session.get("selectedFileId"), file._id
      assert.ok called
      assert.equal calledArgs[0], "/edit/#{file.projectId}/#{file.path}"
      assert.ok !fileTree.isOpen file.path

    it 'should set selectedFileId and open for dir, but not navigate', ->
      fileTree.select dir
      assert.equal Session.get("selectedFileId"), dir._id
      assert.ok !called
      assert.isTrue fileTree.isOpen dir.path

  describe 'sessionPaths', ->
    sessionPaths = null
    sessionId = null

    beforeEach ->
      sessionId = Meteor.uuid()
      fileTree = new FileTree
      sessionPaths = {}

    it 'should return empty array for unknown path', ->
      assert.deepEqual fileTree.getSessionsInFile('ramd.path'), []

    it 'should set a single path', ->
      path = 'file.txt'
      sessionPaths[sessionId] = path
      fileTree.setSessionPaths sessionPaths
      sessionIds = fileTree.getSessionsInFile path
      assert.deepEqual sessionIds, [sessionId]

    it 'should show session in parent if parent is closed', ->
      path = 'parent/file.txt'
      sessionPaths[sessionId] = path
      fileTree.setSessionPaths sessionPaths
      assert.deepEqual fileTree.getSessionsInFile(path), []
      assert.deepEqual fileTree.getSessionsInFile('parent'), [sessionId]

    it 'should show two sessions in different files', ->
      path1 = 'file1.txt'
      sessionId2 = Meteor.uuid()
      path2 = 'file2.coffee'
      sessionPaths[sessionId] = path1
      sessionPaths[sessionId2] = path2
      fileTree.setSessionPaths sessionPaths
      assert.deepEqual fileTree.getSessionsInFile(path1), [sessionId]
      assert.deepEqual fileTree.getSessionsInFile(path2), [sessionId2]

    it 'should show two sessions in the same file', ->
      path = 'fileA2.txt'
      sessionId2 = Meteor.uuid()
      sessionPaths[sessionId] = path
      sessionPaths[sessionId2] = path
      fileTree.setSessionPaths sessionPaths
      assert.deepEqual fileTree.getSessionsInFile(path), [sessionId, sessionId2]

    it 'should show two sessions in the same file if one is in child invisible file', ->
      path1 = 'dir9'
      sessionId2 = Meteor.uuid()
      path2 = 'dir9/file2.coffee'
      sessionPaths[sessionId] = path1
      sessionPaths[sessionId2] = path2
      fileTree.setSessionPaths sessionPaths
      assert.deepEqual fileTree.getSessionsInFile(path1), [sessionId, sessionId2]
      assert.deepEqual fileTree.getSessionsInFile(path2), []

###
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
