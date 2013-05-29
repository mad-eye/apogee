Package.describe({
  summary: "Sets Session.id"
});

Package.on_use(function (api) {
  api.add_files("sessionId.js", "client");
});
