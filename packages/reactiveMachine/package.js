Package.describe({
  summary: "A ReactiveMachine object to allow rich, reactive objects."
});

Package.on_use(function (api) {
  api.use("coffeescript", "client");
  api.add_files(["definePropertyShim.coffee", "reactiveMachine.coffee"], "client");
});
