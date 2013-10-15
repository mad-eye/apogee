Package.describe({
  summary: "Sets Session.id"
});

Package.on_use(function (api) {
  api.use('session', 'client');
  api.add_files("sessionId.js", "client");
});
