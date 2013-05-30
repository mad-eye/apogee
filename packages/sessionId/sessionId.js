var migratedSessionId = null;

if (Meteor._reload) {
  var migrationData = Meteor._reload.migrationData('sessionId');
  if (migrationData && migrationData.id) {
    migratedSessionId = migrationData.id
  }
}

Session.id = migratedSessionId || Meteor.uuid()

if (Meteor._reload) {
  Meteor._reload.onMigrate('sessionId', function () {
    return [true, {id: Session.id}];
  });
}


