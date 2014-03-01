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
      if @project.scratch
        @addSkill("scratchProject", silent:true)
      if !(@project.scratch or @project.impressJS)
        @addSkill("standardProject", silent:true)

  #options:
  #  dismissed: false # if learned from dismissing an alert
  #  silent: false    # if learned passively (ie, loading a standard project)
  addSkill: (skill, options={})->
    return if @hasLearnedSkill skill
    Session.set "skillLearned", true unless options.silent
    if options.dismissed
      Events.record "skillDismissed", skill: skill
    else
      Events.record "skillLearned", skill: skill
    @workspace.addSkill skill

  getLearnedSkills: ->
    @workspace?.skillsLearned or {}

  hasLearnedSkill: (skill) -> return skill of @getLearnedSkills()

  getPromo: ->
    return if Session.get "skillLearned"
    for skill in @skillOrder
      continue if @hasLearnedSkill skill
      nextSkill = @skills()[skill]
      continue unless nextSkill.teachable()
      nextSkill.handle = skill
      nextSkill.level = "info"
      nextSkill.onClose = =>
        @addSkill nextSkill.handle, dismissed:true
      return nextSkill

  skillOrder: ["saving", "sharing", "standardProject", "terminal", "scratchProject", "tunnel"]

  skills: ->
    saving:
      title: 'This file has been modified.'
      message: 'Try saving a file! Files are saved right back to the file system where <code>madeye</code> is running'
      raw: true
      teachable: =>
        return _isStandardProject(@project) and MadEye.editorState.canSave()

    sharing:
      title: "Share your project's URL."
      message: "MadEye is more fun with your teammates"
      teachable: ->
        true

    standardProject:
      title: "Share a project from your computer."
      message: 'MadEye can be used on projects on your own filesystem.  Go to <a target="_blank" href="/">madeye.io</a> for more details.'
      raw: true
      teachable: ->
        !_isStandardProject(@project)

    scratchProject:
      title: "Make a scratch project."
      message: 'MadEye can be used for scratch projects, not tied to any filesystem.  Go to <a target="_blank" href="/scratch">Try it out now!</a>'
      raw: true
      teachable: ->
        !_isStandardProject(@project)

    terminal:
      message: "Did you know you can share you terminal output?  Try <code>madeye --terminal</code>"
      raw: true
      teachable: =>
        _isStandardProject(@project)

    tunnel:
      message: "You can share your local web server with your teammates. Try <code>madeye --tunnel [PORT]</code>"
      raw: true
      teachable: =>
        _isStandardProject(@project)

_isStandardProject = (project)->
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
