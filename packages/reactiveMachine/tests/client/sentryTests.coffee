describe 'Sentries:', ->
  assert = chai.assert

  describe 'basic sentries', ->

    myObj = null
    MyObj = null
    before ->
      class MyObj extends Reactor
        @property 'foo'
        @property 'bar'
        @property 'baz'
        @sentry 'foo2bar', (computation) ->
          return unless @foo?
          @bar = @foo.toUpperCase()

        @sentry 'oneTime', (computation) ->
          return unless @bar?
          @baz = @bar.replace('cat', 'dog')
          computation.stop()


    beforeEach ->
      myObj = new MyObj()

    it 'should run reactively', ->
      myObj.foo = 'hat'
      Deps.flush()
      assert.equal myObj.bar, 'HAT'

    it 'should allow computation.stop()', ->
      myObj.bar = '1cat'
      Deps.flush()
      assert.equal myObj.baz, '1dog'
      myObj.bar = '2cat'
      Deps.flush()
      assert.equal myObj.baz, '1dog'
