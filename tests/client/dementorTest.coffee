Meteor.startup ->
  describe 'Dementor Methods', ->
    assert = chai.assert

    describe 'registerProject', ->

      it 'should return correct error if version is out of date', (done) ->
        projectName = "oldProject-#{Random.hexString 6}"
        Meteor.call 'registerProject',
          version: '0.1.5'
          projectName: projectName
          os:
            platform: 'darwin'
            arch: 'x64'

        , (err, response) ->
          assert.ok err, 'Should return an error'
          assert.equal err.reason, 'VersionOutOfDate'
          done()

      it 'should create and open a new project', (done) ->
        projectName = "project-#{Random.hexString 6}"
        registerAndCheckProject projectName, null, done

      it 'should open an existing project', (done) ->
        projectName = "project-#{Random.hexString 6}"
        Meteor.call 'makeProject', null, projectName, (err, pid) ->
          throw err if err
          registerAndCheckProject projectName, pid, done

      it 'should create a new project with a supplied id', (done) ->
        projectName = "project-#{Random.hexString 6}"
        pid = Random.id()
        registerAndCheckProject projectName, pid, done

      it 'should give warning if node version is out of date', (done) ->
        projectName = "oldNodeProject-#{Random.hexString 6}"
        Meteor.call 'registerProject',
          version: '0.9.0'
          projectName: projectName
          nodeVersion: 'v0.8.13'
        , (err, result) ->
          assert.ok !err, 'Should not return an error'
          assert.ok result
          assert.ok result.warning
          assert.ok result.projectId
          done()



#projectId can be null
registerAndCheckProject = (projectName, projectId, done) ->
  assert = chai.assert
  Meteor.call 'registerProject',
    version: '2.1.5'
    projectName: projectName
    projectId: projectId
  , (err, results) ->
    assert.ok !err, 'Should not return an error'
    assert.ok results
    assert.ok results.projectId
    if projectId
      assert.equal results.projectId, projectId
    Meteor.call 'findProject', results.projectId, (err, project) ->
      throw err if err
      assert.ok project
      assert.equal project.name, projectName
      assert.equal project._id, results.projectId
      assert.ok !project.closed
      done()


