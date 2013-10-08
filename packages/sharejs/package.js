Package.describe({
  summary: "Files needed for a sharejs-based ace editor"
});

Package.on_use(function (api, where) {
  api.use(['reactive-ace'], "client")
  api.add_files(['bcsocket-uncompressed.js'], "client")
  api.add_files([
    'ShareJS/webclient/share.uncompressed.js',
    'ShareJS/webclient/ace.js',
    'ShareJS/webclient/text2.uncompressed.js'
  ], "client")
});
