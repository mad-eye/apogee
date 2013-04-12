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

  describe 'sessionPaths reactivity', ->
    sessionPaths = null
    sessionId1 = null
    sessionId2 = null

    beforeEach ->
      sessionId1 = Meteor.uuid()
      sessionId2 = Meteor.uuid()
      fileTree = new FileTree
      sessionPaths = {}

    it 'should react to a single path changing', ->
      path1 = 'rfile1.txt'
      path2 = 'rfile2.txt'
      sessionPaths[sessionId1] = path1
      fileTree.setSessionPaths sessionPaths
      inPath1 = null
      inPath2 = null
      Deps.autorun ->
        inPath1 = sessionId1 in fileTree.getSessionsInFile(path1)
      Deps.autorun ->
        inPath2 = sessionId1 in fileTree.getSessionsInFile(path2)
      Deps.flush()
      assert.isTrue inPath1
      assert.isFalse inPath2
      sessionPaths[sessionId1] = path2
      fileTree.setSessionPaths sessionPaths
      Deps.flush()
      assert.isFalse inPath1
      assert.isTrue inPath2

    #Should be in parent when it's closed, and child when open
    it 'should react to a parent opening/closing', ->
      path1 = 'dir/rfile1.txt'
      path2 = 'dir'
      sessionPaths[sessionId1] = path1
      fileTree.setSessionPaths sessionPaths
      inPath1 = null
      inPath2 = null
      Deps.autorun ->
        inPath1 = sessionId1 in fileTree.getSessionsInFile(path1)
      Deps.autorun ->
        inPath2 = sessionId1 in fileTree.getSessionsInFile(path2)
      Deps.flush()
      assert.isFalse inPath1
      assert.isTrue inPath2
      fileTree.open path2
      Deps.flush()
      assert.isTrue inPath1
      assert.isFalse inPath2
      fileTree.close path2
      Deps.flush()
      assert.isFalse inPath1
      assert.isTrue inPath2

    it 'should react to a single path changing to an invisible path', ->
      path0 = 'file3.txt'
      path1 = 'dir/rfile1.txt'
      path2 = 'dir'
      sessionPaths[sessionId1] = path0
      fileTree.setSessionPaths sessionPaths
      inPath0 = null
      inPath1 = null
      inPath2 = null
      Deps.autorun ->
        inPath0 = sessionId1 in fileTree.getSessionsInFile(path0)
      Deps.autorun ->
        inPath1 = sessionId1 in fileTree.getSessionsInFile(path1)
      Deps.autorun ->
        inPath2 = sessionId1 in fileTree.getSessionsInFile(path2)
      Deps.flush()
      assert.isTrue inPath0
      assert.isFalse inPath1
      assert.isFalse inPath2
      sessionPaths[sessionId1] = path1
      fileTree.setSessionPaths sessionPaths
      Deps.flush()
      assert.isFalse inPath0
      assert.isFalse inPath1
      assert.isTrue inPath2
      fileTree.open path2
      Deps.flush()
      assert.isFalse inPath0
      assert.isTrue inPath1
      assert.isFalse inPath2

    it 'should remove disappearing sessionId', ->
      path1 = 'oscar'
      path2 = 'grouch'
      sessionPaths[sessionId1] = path1
      sessionPaths[sessionId2] = path2
      fileTree.setSessionPaths sessionPaths
      path1Ids = null
      path2Ids = null
      Deps.autorun ->
        path1Ids = fileTree.getSessionsInFile(path1)
      Deps.autorun ->
        path2Ids = fileTree.getSessionsInFile(path2)
      Deps.flush()
      sessionPaths[sessionId1] = null
      fileTree.setSessionPaths sessionPaths
      Deps.flush()
      assert.deepEqual path1Ids, []
      assert.deepEqual path2Ids, [sessionId2]


    it 'should react to one of two sessions changing', ->
      path1_1 = 'file1.js'
      path1_2 = 'anotherJs.js'
      path2_1 = 'stay.put'
      sessionPaths[sessionId1] = path1_1
      sessionPaths[sessionId2] = path2_1
      fileTree.setSessionPaths sessionPaths
      path1_1Ids = null
      path1_2Ids = null
      path2_1Ids = null
      Deps.autorun ->
        path1_1Ids = fileTree.getSessionsInFile(path1_1)
      Deps.autorun ->
        path1_2Ids = fileTree.getSessionsInFile(path1_2)
      Deps.autorun ->
        path2_1Ids = fileTree.getSessionsInFile(path2_1)
      Deps.flush()
      assert.deepEqual path1_1Ids, [sessionId1], "SessionId1 should be in path1_1"
      assert.deepEqual path1_2Ids, []
      assert.deepEqual path2_1Ids, [sessionId2], "SessionId2 should be in path2_1"

      sessionPaths[sessionId1] = path1_2
      fileTree.setSessionPaths sessionPaths
      Deps.flush()
      assert.deepEqual path1_1Ids, []
      assert.deepEqual path1_2Ids, [sessionId1], "SessionId1 should be in path1_2"
      assert.deepEqual path2_1Ids, [sessionId2], "SessionId2 should be in path2_1"


    it 'should react to a session changing to the same path as another session', ->
      path1 = 'bert'
      path2 = 'ernie'
      sessionPaths[sessionId1] = path1
      sessionPaths[sessionId2] = path2
      fileTree.setSessionPaths sessionPaths
      path1Ids = null
      path2Ids = null
      Deps.autorun ->
        path1Ids = fileTree.getSessionsInFile(path1)
      Deps.autorun ->
        path2Ids = fileTree.getSessionsInFile(path2)
      Deps.flush()
      sessionPaths[sessionId1] = path2
      fileTree.setSessionPaths sessionPaths
      Deps.flush()
      assert.deepEqual path1Ids, []
      assert.deepEqual path2Ids, [sessionId1, sessionId2]



    it 'should react to a session leaving the same path as another session', ->
      path1 = 'bert'
      path2 = 'ernie'
      sessionPaths[sessionId1] = path1
      sessionPaths[sessionId2] = path1
      fileTree.setSessionPaths sessionPaths
      path1Ids = null
      path2Ids = null
      Deps.autorun ->
        path1Ids = fileTree.getSessionsInFile(path1)
      Deps.autorun ->
        path2Ids = fileTree.getSessionsInFile(path2)
      Deps.flush()
      assert.deepEqual path1Ids, [sessionId1, sessionId2]
      assert.deepEqual path2Ids, []

      sessionPaths[sessionId2] = path2
      fileTree.setSessionPaths sessionPaths
      Deps.flush()
      assert.deepEqual path1Ids, [sessionId1]
      assert.deepEqual path2Ids, [sessionId2]

