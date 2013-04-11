Meteor.startup ->
  Files.allow
    insert: (userId, doc) -> true

