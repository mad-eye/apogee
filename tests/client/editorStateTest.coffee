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
  
describe "EditorState", ->
  assert = chai.assert

  before ->
    MadEye.editorState ?= new EditorState "editor"
    spy = sinon.spy Router, 'setTemplate'

  after ->
    Router.setTemplate.restore()

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
    it 'should be false when there is no project fweep', ->
      console.log 'ZZZ: first canDiscard'
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

  describe "save", ->
    it "should learn the saving skill when a file is saved"
