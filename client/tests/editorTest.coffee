describe "editorChrome", ->
  assert = chai.assert
  describe "save button", ->
    project = file = null
    projectName = 'fizzik'
    projectId = null
    before ->
      project = new Project
        name: projectName
        closed: false
        isTest: true
      project.save()
      projectId = project._id
      Session.set "projectId", project._id

      file = new File
        projectId: projectId
        path: 'a/path/whee.txt'
        modified: true
        isTest: true
      file.save()
      Session.set "editorFilePath", file.path

      Meteor.flush()

    after ->
      Projects.collection.remove name: projectName
      Files.collection.remove projectId: projectId

    describe "when project.closed and !file.modified", ->
      before ->
        project.closed = false
        project.save()
        file.modified = false
        file.save()
        Meteor.flush()

      it "should have a disabled button", ->
        assert.equal Template.editorChrome.buttonDisabled(), "disabled"
      it 'should not show save spinner', ->
        assert.isFalse Template.editorChrome.showSaveSpinner()
      it 'should have message "Saved"', ->
        assert.equal Template.editorChrome.saveButtonMessage(), "Saved"

    describe "when project.closed and file.modified", ->
      before ->
        project.closed = false
        project.save()
        file.modified = true
        file.save()
        Meteor.flush()

      it "should not have a disabled button", ->
        assert.equal Template.editorChrome.buttonDisabled(), ""
      it 'should not show save spinner', ->
        assert.isFalse Template.editorChrome.showSaveSpinner()
      it 'should have message "Save Locally"', ->
        assert.equal Template.editorChrome.saveButtonMessage(), "Save Locally"





