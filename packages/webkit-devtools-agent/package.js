Package.describe({
  summary: "webkit devtools agent."
});


Npm.depends({"webkit-devtools-agent": "0.1.2"});

Package.on_use(function (api, where) {
  api.add_files('devtools.js', 'server');
});
