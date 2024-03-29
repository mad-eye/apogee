#TODO: Extract this to a MeteorModel test
Meteor.startup ->
  describe "MadEye.Model", ->
    assert = chai.assert

    class TestModel extends MadEye.Model
    TestModels = new Meteor.Collection 'testModels', transform: (doc) ->
      new TestModel doc

    TestModel.prototype.collection = TestModels

    describe "create", ->
      it 'should create a file', ->
        file = TestModel.create {a:'b', c:false}
        assert.ok file._id
        savedFile = TestModels.findOne file._id
        assert.deepEqual savedFile, file

    #TODO these might be failing for a good reason..
    # describe 'save', ->
    #   it 'should save a new File', ->
    #     file = new TestModel {path:'a/path/1233'}
    #     file.save()
    #     assert.ok file._id
    #     savedFile = TestModels.findOne file._id
    #     assert.deepEqual savedFile, file

    #   it 'should update an existing file', ->
    #     file = TestModel.create {a:'b', c:false}
    #     file.a = 'Z'
    #     file.save()
    #     assert.equal file.a, 'Z'
    #     savedFile = TestModels.findOne file._id
    #     console.log "SAVED FILE", savedFile
    #     console.log "FILE", file
    #     assert.equal savedFile, file

    # describe 'update', ->
    #   it 'should update existing fields', ->
    #     file = TestModel.create {a:'b', c:false}
    #     file.update a:'D'
    #     assert.equal file.a, 'D'
    #     savedFile = TestModels.findOne file._id
    #     assert.deepEqual savedFile, file
        

    #   it 'should create new fields', ->
    #     file = TestModel.create {a:'b', c:false}
    #     file.update z:'G'
    #     assert.equal file.z, 'G'
    #     savedFile = TestModels.findOne file._id
    #     assert.deepEqual savedFile, file

    #   it 'should not hit db if field is unchanged', ->
    #     file = TestModel.create {a:'b', c:false}
    #     timesHit = 0
    #     Deps.autorun ->
    #       TestModels.findOne file._id
    #       timesHit++

    #     for i in [1..9]
    #       file.update a:'b'
    #       Deps.flush()

    #     assert.equal timesHit, 1

    #   it 'should update multiple fields', ->
    #     file = TestModel.create {a:'b', c:false}
    #     obj = {}
    #     file.update a:'b', c:true, z:obj
    #     assert.equal file.a, 'b'
    #     assert.equal file.c, true
    #     assert.equal file.z, obj
    #     savedFile = TestModels.findOne file._id
    #     assert.deepEqual savedFile, file

    describe 'remove', ->
      it 'should remove db entry', ->
        file = TestModel.create {a:'b', c:false}
        file.remove()
        savedFile = TestModels.findOne file._id
        assert.isFalse savedFile?

  describe 'Files', ->
    assert = chai.assert

    coffeeFile = null
    binFile = null
    makeFile = null
    before ->
      coffeeFile = MadEye.File.create
        path: 'a/path/cool.coffee'
        isDir: false
      binFile = MadEye.File.create
        path: 'a/nother/path/cat.GIF'
        isDir: false
      makeFile = MadEye.File.create
        path: 'Makefile'
        isDir: true

    it 'should have filename prop', ->
      assert.equal coffeeFile.filename, 'cool.coffee'
      assert.equal binFile.filename, 'cat.GIF'
      assert.equal makeFile.filename, 'Makefile'

    it 'should have depth prop', ->
      assert.equal coffeeFile.depth, 2
      assert.equal binFile.depth, 3
      assert.equal makeFile.depth, 0

    it 'should have parentPath prop', ->
      assert.equal coffeeFile.parentPath, 'a/path'
      assert.equal binFile.parentPath, 'a/nother/path'
      assert.isNull makeFile.parentPath

    it 'should have extension prop', ->
      assert.equal coffeeFile.extension, 'coffee'
      assert.equal binFile.extension, 'GIF'
      assert.isNull makeFile.extension
    
    it 'should have isBinary prop', ->
      assert.isFalse coffeeFile.isBinary
      assert.isTrue binFile.isBinary, '.GIF files should be considered binary'
      assert.isFalse makeFile.isBinary

    it 'should have aceMode prop', ->
      assert.equal coffeeFile.aceMode, 'coffee'
      assert.isFalse binFile.aceMode?
      assert.equal makeFile.aceMode, 'makefile'
