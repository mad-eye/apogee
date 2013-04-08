editorState = null
Meteor.methods
  cleanProject: (projectId)->
    console.log "cleaning project", projectId
    Projects.collection.remove projectId
    Files.collection.remove projectId: projectId

describe "editorChrome", ->
  assert = chai.assert
  describe "save button", ->
    helpers = null
    project = file = null
    projectName = 'fizzik'
    projectId = null
    before ->
      editorState ?= new EditorState "editor"
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
      editorState.setPath file.path

      helpers = Template.editorBar._tmpl_data.helpers

      Meteor.flush()

    after ->
      Meteor.call "cleanProject", projectId

    describe "when project.closed and !file.modified", ->
      before ->
        project.closed = false
        project.save()
        file.modified = false
        file.save()
        Meteor.flush()

      it "should have a disabled button", ->
        assert.equal helpers.buttonDisabled(), "disabled"
      it 'should not show save spinner', ->
        assert.isFalse helpers.showSaveSpinner()

    describe "when project.closed and file.modified", ->
      before ->
        project.closed = false
        project.save()
        file.modified = true
        file.save()
        Meteor.flush()

      it "should not have a disabled button", ->
        assert.equal helpers.buttonDisabled(), ""
      it 'should not show save spinner', ->
        assert.isFalse helpers.showSaveSpinner()





