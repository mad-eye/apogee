#TODO: Extract this to a MeteorModel test
describe "Files (MeteorModel)", ->
  assert = chai.assert

  describe "create", ->
    it 'should create a file', ->
      file = File.create {a:'b', c:false}
      assert.ok file._id
      savedFile = Files.findOne file._id
      assert.deepEqual savedFile, file

  describe 'save', ->
    it 'should save a new File', ->
      file = new File {path:'a/path/1233'}
      file.save()
      assert.ok file._id
      savedFile = Files.findOne file._id
      assert.deepEqual savedFile, file

    it 'should update an existing file', ->
      file = File.create {a:'b', c:false}
      file.a = 'Z'
      file.save()
      assert.equal file.a, 'Z'
      savedFile = Files.findOne file._id
      assert.deepEqual savedFile, file

  describe 'update', ->
    it 'should update existing fields', ->
      file = File.create {a:'b', c:false}
      file.update a:'D'
      assert.equal file.a, 'D'
      savedFile = Files.findOne file._id
      assert.deepEqual savedFile, file
      

    it 'should create new fields', ->
      file = File.create {a:'b', c:false}
      file.update z:'G'
      assert.equal file.z, 'G'
      savedFile = Files.findOne file._id
      assert.deepEqual savedFile, file

    it 'should not hit db if field is unchanged', ->
      file = File.create {a:'b', c:false}
      timesHit = 0
      Deps.autorun ->
        Files.findOne file._id
        timesHit++

      for i in [1..9]
        file.update a:'b'
        Deps.flush()

      assert.equal timesHit, 1

    it 'should update multiple fields', ->
      file = File.create {a:'b', c:false}
      obj = {}
      file.update a:'b', c:true, z:obj
      assert.equal file.a, 'b'
      assert.equal file.c, true
      assert.equal file.z, obj
      savedFile = Files.findOne file._id
      assert.deepEqual savedFile, file

  describe 'remove', ->
    it 'should remove db entry', ->
      file = File.create {a:'b', c:false}
      file.remove()
      savedFile = Files.findOne file._id
      assert.isFalse savedFile?



