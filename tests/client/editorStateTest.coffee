makeProject = (data) ->
  project = new Project
    name: Random.hexString(6)
    isTest: true
  _.extend project, data
  project.save()
  Session.set "projectId", project._id
  Deps.flush()
  return project._id

makeFile = (data) ->
  file = MadEye.File.create
    isTest: true
    path: 'a/b/c.txt'
  _.extend file, data
  file.save()
  Deps.flush()
  return file._id
  
appendEditor = (editorId) ->
  $("<p><div id='#{editorId}' style='height:40px; width: 300px; position: relative; float: left; margin-right: 15px; margin-bottom: 30px;'></div></p>").appendTo $("#tests")

randomId = () ->
  return Math.floor( Math.random() * 1000000 + 1)

setupEditor = (editorId) ->
  appendEditor editorId
  editorState = new EditorState editorId
  editorState.attach()
  return editorState

describe "EditorState", ->
  assert = chai.assert

  before ->
    MadEye.editorState ?= new EditorState "editor"
    #spy = sinon.spy Router, 'setTemplate'

  after ->
    #Router.setTemplate.restore()

  describe "canSave", ->
    it 'should be false when there is no project', ->
      Session.set 'projectId', Random.id()
      Deps.flush()
      assert.isFalse MadEye.editorState.canSave()

    it 'should be false when the project is closed', ->
      projectId = makeProject closed: true
      assert.isFalse MadEye.editorState.canSave()
    
    it 'should be false when there is no file', ->
      projectId = makeProject closed: false
      MadEye.editorState.fileId = Random.id()
      Deps.flush()
      assert.isFalse MadEye.editorState.canSave()
    
    it 'should be false when the file is scratch', ->
      projectId = makeProject closed: false
      fileId = makeFile projectId: projectId, scratch:true
      MadEye.editorState.fileId = fileId
      Deps.flush()
      assert.isFalse MadEye.editorState.canSave()

    it 'should be false when the file is not modified', ->
      projectId = makeProject closed: false
      fileId = makeFile projectId: projectId, modified:false
      MadEye.editorState.fileId = fileId
      Deps.flush()
      assert.isFalse MadEye.editorState.canSave()

    it 'should be true when the file is modified', ->
      projectId = makeProject closed: false
      fileId = makeFile projectId: projectId, modified:true
      MadEye.editorState.fileId = fileId
      Deps.flush()
      assert.isTrue MadEye.editorState.canSave()

  describe 'canDiscard', ->
    it 'should be false when there is no project', ->
      Session.set 'projectId', Random.id()
      Deps.flush()
      assert.isFalse MadEye.editorState.canDiscard()

    it 'should be false when the project is closed', ->
      projectId = makeProject closed: true
      assert.isFalse MadEye.editorState.canDiscard()
    
    it 'should be false when there is no file', ->
      projectId = makeProject closed: false
      MadEye.editorState.fileId = Random.id()
      Deps.flush()
      assert.isFalse MadEye.editorState.canDiscard()
    
    it 'should be false when the file is not deletedInFs', ->
      projectId = makeProject closed: false
      fileId = makeFile projectId: projectId, deletedInFs:false
      MadEye.editorState.fileId = fileId
      Deps.flush()
      assert.isFalse MadEye.editorState.canDiscard()

    it 'should be true when the file is deletedInFs', ->
      projectId = makeProject closed: false
      fileId = makeFile projectId: projectId, deletedInFs:true
      MadEye.editorState.fileId = fileId
      Deps.flush()
      assert.isTrue MadEye.editorState.canDiscard()

  describe "loadFile", ->
    projectId = fileId = null
    editorState = null
    beforeEach ->
      sinon.stub(Meteor, 'call')
      sinon.stub(MadEye.sharejs, 'open')
      sinon.stub(Errors, 'handleError')
      projectId = makeProject closed: false
      fileId = makeFile projectId: projectId
      editorState = setupEditor("editor" + randomId())

    afterEach ->
      MadEye.sharejs.open.restore()
      Meteor.call.restore()
      Errors.handleError.restore()

    makeDoc = (data) ->
      return _.extend({
        version: 1
        emit: ->
        connection: id: 100
        attach_ace: sinon.stub()
        detach_ace: ->
        on: ->
      }, data)

    it "should open an existing doc if there is one", ->
      docSnapshot = 'abcd'
      doc = makeDoc
        name: fileId
        snapshot: docSnapshot
      MadEye.sharejs.open.callsArgWith(3, null, doc)
      editorState.loadFile Files.findOne(fileId)
      assert.ok MadEye.sharejs.open.calledWith(fileId, "text2", "#{MadEye.bolideUrl}/channel")
      assert.ok Meteor.call.neverCalledWith('requestFile')
      assert.ok doc.attach_ace.called
      assert.equal Errors.handleError.callCount, 0

    it "should open a new doc and use dementor contents if there isn't one", ->
      doc = makeDoc
        name: fileId
        version: 0
        snapshot: ''
      MadEye.sharejs.open.callsArgWith(3, null, doc)
      Meteor.call.withArgs('requestFile', projectId, fileId).callsArgWith(3, null, {})
      editorState.loadFile Files.findOne(fileId)
      assert.ok MadEye.sharejs.open.calledWith(fileId, "text2", "#{MadEye.bolideUrl}/channel"), 'sharejs.open should be called'
      assert.ok Meteor.call.calledWith('requestFile'), "Should Meteor.call('requestFile')"
      assert.ok doc.attach_ace.called, "Should called doc.attach_ace"
      assert.equal Errors.handleError.callCount, 0

    it "should report sharejs error if it occurs", ->
      docSnapshot = 'abcd'
      doc = makeDoc
        name: fileId
        snapshot: docSnapshot
      MadEye.sharejs.open.callsArgWith(3, "SHAREJS ERROR", null)
      editorState.loadFile Files.findOne(fileId)
      assert.ok MadEye.sharejs.open.calledWith(fileId, "text2", "#{MadEye.bolideUrl}/channel")
      assert.ok Meteor.call.neverCalledWith('requestFile')
      assert.equal doc.attach_ace.callCount, 0
      assert.ok Errors.handleError.called

    it "should report requestFile error if it occurs", ->
      doc = makeDoc
        name: fileId
        version: 0
        snapshot: ''
      MadEye.sharejs.open.callsArgWith(3, null, doc)
      error = new Meteor.Error 500, "File Not Found", "DEMENTOR ERROR"
      Meteor.call.withArgs('requestFile', projectId, fileId).callsArgWith(3, error, null)
      editorState.loadFile Files.findOne(fileId)
      assert.ok MadEye.sharejs.open.calledWith(fileId, "text2", "#{MadEye.bolideUrl}/channel"), 'sharejs.open should be called'
      assert.ok Meteor.call.calledWith('requestFile'), "Should Meteor.call('requestFile')"
      assert.equal doc.attach_ace.callCount, 0, "Should not attach ace on dementor error"
      assert.ok Errors.handleError.called, "Should call handleError on dementor error"

    it "should do nothing if the file is already loaded"
    it "should reattach the share doc if the editor has been detached"
