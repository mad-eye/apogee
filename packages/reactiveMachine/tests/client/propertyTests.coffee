describe 'Reactive Properties:', ->
  assert = chai.assert

  describe 'basic properties', ->

    myObj = null
    before ->
      class MyObj extends Reactor
        @property 'foo'
        @property 'ronly', write:false
        @property 'wonly', read:false
        @property 'internal', read:false, write:false

      myObj = new MyObj()

    it 'should be reactive', ->
      fooVal = null
      Deps.autorun ->
        fooVal = myObj.foo
      myObj.foo = 'abc'
      Deps.flush()
      assert.equal fooVal, 'abc'

    it 'readOnly should not be writeable', ->
      myObj._set('ronly', null)
      myObj.ronly = 5
      assert.isNull myObj.ronly

    it 'readOnly should be reactive', ->
      ronlyVal = null
      Deps.autorun ->
        ronlyVal = myObj.ronly
      myObj._set('ronly', 'abd')
      Deps.flush()
      assert.equal ronlyVal, 'abd'

    it 'writeOnly should not be readable', ->
      myObj.wonly = 5
      assert.isNull myObj.wonly

    it 'writeOnly should be reactive', ->
      wonlyVal = null
      Deps.autorun ->
        wonlyVal = myObj._get 'wonly'
      myObj.wonly = 'dcs'
      Deps.flush()
      assert.equal wonlyVal, 'dcs'

    it 'private should be reactive', ->
      internalVal = null
      Deps.autorun ->
        internalVal = myObj._get 'internal'
      myObj._set 'internal', 'deq'
      Deps.flush()
      assert.equal internalVal, 'deq'

    it 'private should not be readable', ->
      myObj._set 'internal', 5
      assert.isNull myObj.internal

    it 'private should not be settable', ->
      myObj._set 'internal', null
      myObj.internal = 6
      assert.isNull myObj._get('internal')

