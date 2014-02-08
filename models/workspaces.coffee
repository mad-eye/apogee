class MadEye.Workspace extends MadEye.Model
  constructor: (data) ->
    super data

  #skills are added when an action is performed or the "skill description" is dismissed
  addSkill: (skill) ->
    @skillsLearned ?= {}
    return if @skillsLearned[skill]
    @skillsLearned[skill] = true
    @save()

@Workspaces  = new Meteor.Collection "workspaces", transform: (doc) ->
  new MadEye.Workspace doc

MadEye.Workspace.prototype.collection = @Workspaces

