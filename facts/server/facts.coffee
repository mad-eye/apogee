Facts.setUserIdFilter (userId) ->
  user = Meteor.users.findOne(userId)
  return user and user.admin
