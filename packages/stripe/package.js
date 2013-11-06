Package.describe({
  summary: "Stripe.js and Node-Stripe brought to Meteor."
});

Npm.depends({ stripe: "2.0.1" });

Package.on_use(function(api) {
  api.use(['coffeescript'], 'server');
  if (api.export) // ensure backwards compatibility with Meteor pre-0.6.5
    api.export('Stripe');

  api.add_files("stripe.coffee", "server");

});
