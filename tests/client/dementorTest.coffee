Meteor.startup ->
  describe 'Dementor Methods', ->
    assert = chai.assert

    describe 'registerProject', ->

      it 'should return correct error if version is out of date', (done) ->
        projectName = "oldProject-#{Random.hexString 6}"
        Meteor.call 'registerProject',
          version: '0.1.5'
          projectName: projectName
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

#projectId can be null
registerAndCheckProject = (projectName, projectId, done) ->
  assert = chai.assert
  Meteor.call 'registerProject',
    version: '2.1.5'
    projectName: projectName
    projectId: projectId
  , (err, pid) ->
    assert.ok !err, 'Should not return an error'
    assert.ok pid
    if projectId
      assert.equal pid, projectId
    Meteor.call 'findProject', pid, (err, project) ->
      throw err if err
      assert.ok project
      assert.equal project.name, projectName
      assert.ok !project.closed
      done()


