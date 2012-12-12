Template.tests.rendered = ->
  if window.mochaPhantomJS
    expect = chai.expect
    mochaPhantomJS.run()
  else
    mocha.run();
  