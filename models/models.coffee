class Project extends MadEye.Model

@Projects = new Meteor.Collection 'projects', transform: (doc) ->
  new Project doc
Project.prototype.collection = @Projects
@Project = Project


class NewsletterEmail extends MadEye.Model

@NewsletterEmails = new Meteor.Collection 'newsletterEmails', transform: (doc) ->
  new NewsletterEmail doc
NewsletterEmail.prototype.collection = @NewsletterEmails


