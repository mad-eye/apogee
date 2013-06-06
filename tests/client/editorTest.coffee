Meteor.methods
  cleanProject: (projectId)->
    console.log "cleaning project", projectId
    Projects.remove projectId
    Files.remove projectId: projectId

describe "editorChrome", ->
  assert = chai.assert
  describe "save button", ->
    helpers = null
    project = file = null
    projectName = 'fizzik'
    projectId = null
    before ->
      MadEye.editorState ?= new EditorState "editor"
      project = new Project
        name: projectName
        closed: false
        isTest: true
      project.save()
      projectId = project._id
      Session.set "projectId", project._id

      file = MadEye.File.create
        projectId: projectId
        path: 'a/path/whee.txt'
        modified: true
        isTest: true
      file.save()
      MadEye.editorState.fileId = file._id
      helpers = Template.editorBar._tmpl_data.helpers

      Meteor.flush()

    after ->
      Meteor.call "cleanProject", projectId

    describe "when project.closed==false and file.modified==false", ->
      before ->
        project.closed = false
        project.save()
        file.modified = false
        file.save()
        Meteor.flush()

      it "should have a disabled button", ->
        #Hack, but this extra-flushes for mocha-phantomjs, which needs it.
        Meteor.flush()
        assert.equal helpers.buttonDisabled(), "disabled"
      it 'should not show save spinner', ->
        #Hack, but this extra-flushes for mocha-phantomjs, which needs it.
        Meteor.flush()
        assert.isFalse helpers.showSaveSpinner()

    describe "when project.closed==false and file.modified==true", ->
      before ->
        project.closed = false
        project.save()
        file.modified = true
        file.save()
        Meteor.flush()

      it "should not have a disabled button", ->
        #Hack, but this extra-flushes for mocha-phantomjs, which needs it.
        Meteor.flush()
        assert.equal helpers.buttonDisabled(), ""
      it 'should not show save spinner', ->
        #Hack, but this extra-flushes for mocha-phantomjs, which needs it.
        Meteor.flush()
        assert.isFalse helpers.showSaveSpinner()

    describe "when project.closed==true and file.modified==true", ->
      before ->
        project.closed = true
        project.save()
        file.modified = true
        file.save()
        Meteor.flush()

      it "should have a disabled button", ->
        #Hack, but this extra-flushes for mocha-phantomjs, which needs it.
        Meteor.flush()
        assert.equal helpers.buttonDisabled(), "disabled"
      it 'should not show save spinner', ->
        #Hack, but this extra-flushes for mocha-phantomjs, which needs it.
        Meteor.flush()
        assert.isFalse helpers.showSaveSpinner()

    describe "when project.closed==true and file.modified==true", ->
      before ->
        project.closed = true
        project.save()
        file.modified = true
        file.save()
        Meteor.flush()

      it "should  have a disabled button", ->
        #Hack, but this extra-flushes for mocha-phantomjs, which needs it.
        Meteor.flush()
        assert.equal helpers.buttonDisabled(), "disabled"
      it 'should not show save spinner', ->
        #Hack, but this extra-flushes for mocha-phantomjs, which needs it.
        Meteor.flush()
        assert.isFalse helpers.showSaveSpinner()





