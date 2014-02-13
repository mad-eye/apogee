class @FeaturePromoter
  constructor: ()->
    @initialize()

  initialize: ->
    Meteor.autorun (computation) =>
      return unless @project
      if @project.tunnels?.terminal
        @addSkill("terminal")
      if @project.tunnels?.webTunnel
        @addSkill("tunnel")
      if ProjectStatuses.find(projectId: @project._id).count() >= 2
        @addSkill("sharing")

  addSkill: (skill)->
    Session.set "skillLearned", true
    Events.record "skillLearned", skill: skill
    @workspace.addSkill skill

  getLearnedSkills: ->
    @workspace?.skillsLearned or {}

  nextUnlearnedSkill: ->
    currentSkills = @getLearnedSkills()
    for skill in @skillOrder
      unless skill of currentSkills
        nextSkill = @skills()[skill]
        nextSkill['handle']  = skill
        return nextSkill

  getPromo: ->
    return if Session.get "skillLearned"
    nextSkill = @nextUnlearnedSkill()
    if nextSkill?.teachable()
      nextSkill.onClose = =>
        @addSkill nextSkill.handle
      nextSkill.level = "info"
      return nextSkill

  skillOrder: ["saving", "sharing", "terminal", "tunnel"]

  skills: ->
    saving:
      title: 'This file has been modified.'
      message: 'Try saving a file! Files are saved right back to the file system where <code>madeye</code> is running'
      raw: true
      teachable: =>
        return @_isStandardProject(@project) and MadEye.editorState.canSave()

    sharing:
      title: "Share your project's URL."
      message: "MadEye is more fun with your teammates"
      teachable: ->
        true

    terminal:
      message: "Did you know you can share you terminal output?  Try <code>madeye --terminal</code>"
      raw: true
      teachable: =>
        @_isStandardProject(@project)

    tunnel:
      message: "You can share your local web server with your teammates. Try <code>madeye --tunnel [PORT]</code>"
      raw: true
      teachable: =>
        @_isStandardProject(@project)

  _isStandardProject: (project)->
    project and not project.impressJS and not project.scratch

Reactor.mixin FeaturePromoter.prototype
Reactor.define FeaturePromoter.prototype, 'project'
Reactor.define FeaturePromoter.prototype, 'workspace'

MadEye.featurePromoter = new FeaturePromoter()

Meteor.autorun ->
  return unless project = getProject()
  return unless workspace = Workspace.get()
  MadEye.featurePromoter.project = project
  MadEye.featurePromoter.workspace = workspace
