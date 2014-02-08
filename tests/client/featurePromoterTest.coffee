assert = chai.assert

Meteor.startup ->
  describe 'FeaturePromoter', ->
    featurePromoter = null
    _oldEditorState = null
    project = null
    
    beforeEach ->
      workspace = new MadEye.Workspace
      project = new Project()
      project.tunnels = {}
      _oldEditorState = MadEye.editorState
      MadEye.editorState = canSave: -> true
      featurePromoter = new FeaturePromoter()
      featurePromoter.project = project
      featurePromoter.workspace = workspace
      
    afterEach ->
      MadEye.editorState = _oldEditorState

    it "should suggest saving a file to a new user with a modified file", ->
      promo = featurePromoter.getPromo()
      assert.equal promo.handle, "saving"

    it "should suggest no promotions if the user has no save skill and the current file is unmodified", ->
      MadEye.editorState = canSave: -> false
      promo = featurePromoter.getPromo()
      assert.ok !promo

    it "should suggest sharing if the user has saved", ->
      featurePromoter.addSkill "saving"
      promo = featurePromoter.getPromo()
      assert.equal promo.handle, "sharing"
      
    it "should learn the sharing skill when project statuses exceed two", ->
      ProjectStatuses.insert({'projectId': featurePromoter.project._id})
      ProjectStatuses.insert({'projectId': featurePromoter.project._id})
      Deps.flush()
      assert.ok "sharing" of featurePromoter.getLearnedSkills()
    
    it "should learn a skill when the alert is closed", ->
      promo = featurePromoter.getPromo()
      promoHandle = promo.handle
      promo.onClose()
      console.log promoHandle, featurePromoter.getLearnedSkills()
      assert promoHandle of featurePromoter.getLearnedSkills()

    it "should learn the terminal skill when the project includes a terminal", ->
      project = new Project {tunnels: {terminal: true}}
      featurePromoter.project = project
      Deps.flush()
      assert "terminal" of featurePromoter.getLearnedSkills()

    it "should learn the tunnel skill when the project includes a web tunnel", ->
      project = new Project {tunnels: {webTunnel: true}}
      featurePromoter.project = project
      Deps.flush()
      assert "tunnel" of featurePromoter.getLearnedSkills()

    it "should record an event when a skill is learned", ->
      project.save()
      Session.set "projectId", project._id
      featurePromoter.addSkill "blades"
      Deps.flush()
      console.log "ALL EVENTS", Events.find(projectId: project._id).fetch()
      assert Events.findOne {projectId: project._id, skill: "blades"}
