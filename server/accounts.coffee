log = new Logger 'accounts'

Meteor.publish 'userData', ->
  return Meteor.users.find {_id: this.userId}, fields:
    name: 1
    email: 1
    type: 1

Accounts.onCreateUser (options, user) ->
  user.type = switch
    when options.anonymous then 'anonymous'
    when user.services?.google then 'google'
    when user.services?.password then 'password'

  switch user.type
    when 'google'
      user.name = user.services.google.name
      user.email = user.services.google.email
    when 'password'
      #TODO: Make this a bit tighter
      user.email = user.emails[0].address
      #TODO: Parse; use user.profile.name ?
      user.name = user.username || user.email
    when 'anonymous'
      user.name = generateRandomName()

  # Give admin powers to madeye people
  if user.email && user.email.indexOf('@') > -1
    user.admin = true if user.email.split('@')[1] == 'madeye.io'

  Workspaces.insert userId: user._id
  return user

Meteor.startup ->
  googleConfig = Accounts.loginServiceConfiguration.findOne(service:'google')
  return if googleConfig
  unless Meteor.settings.googleSecret
    console.error "Missing googleSecret; cannot configure"
    return
  unless Meteor.settings.googleClientId
    console.error "Missing googleClientId; cannot configure"
    return
  Accounts.loginServiceConfiguration.insert
    service: 'google'
    clientId: Meteor.settings.googleClientId
    secret: Meteor.settings.googleSecret

# XXX: This is to assign names to pre-name anonymous accounts
# If we had login hooks, we'd use that instead.
Meteor.methods
  assignName: ->
    return if Meteor.user()?.name
    Meteor.users.update(Meteor.userId(), name: generateRandomName())


##
# Generate a name such as "Icy Panda" or "Stubborn Newt"
generateRandomName = ->
  adjective = ADJECTIVES[Math.floor(Random.fraction()*ADJECTIVES.length)]
  animal = ANIMALS[Math.floor(Random.fraction()*ANIMALS.length)]
  "#{adjective} #{animal}"

ANIMALS = ['Ant', 'Badger', 'Coati', 'Duck', 'Emu', 'Ferret', 'Gecko',
  'Hamster', 'Iguana', 'Jaguar', 'Kangaroo', 'Lemming', 'Meerkat', 'Newt',
  'Ocelot', 'Platypus', 'Quoll', 'Rhinoceros', 'Skunk', 'Tapir', 'Uakari',
  'Vervet', 'Walrus', 'Weasel', 'Yak', 'Zebra']

ADJECTIVES = ['Adept', 'Burly', 'Crafty', 'Dapper', 'Electric', 'Feisty',
  'Furtive', 'Gleeful', 'Hangry', 'Icy', 'Jocular', 'Klutzy', 'Languid', 'Merry',
  'Naughty', 'Opulent', 'Perky', 'Queasy', 'Ripped', 'Stubborn', 'Thunderous',
  'Unkempt', 'Velvetine', 'Woozy', 'Wrathful', 'Zesty']

