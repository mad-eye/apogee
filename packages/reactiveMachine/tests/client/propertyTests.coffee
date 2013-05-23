describe 'Reactive Properties:', ->
  assert = chai.assert

  describe 'basic properties', ->

    myObj = null
    before ->
      class MyObj extends Reactor
        @property 'foo'
        @property 'ronly', set:false
        @property 'wonly', get:false
        @property 'internal', get:false, set:false

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

  describe 'complex properties', ->
    complexObj = null
    valStore = null

    before ->
      class ComplexObj extends Reactor
        @property 'complex',
          get: ->
            valStore['complex']
          set: (value) ->
            valStore['complex'] = value

      complexObj = new ComplexObj()

    beforeEach ->
      valStore = {}

    it 'should be reactive', ->
      complexVal = null
      Deps.autorun ->
        complexVal = complexObj.complex
      complexObj.complex = 'abc'
      Deps.flush()
      assert.equal complexVal, 'abc'

    it 'should call the setter on write, not be stored internally', ->
      complexObj.complex = 'ppp'
      assert.equal valStore['complex'], 'ppp'
      assert.ok !complexObj._keys['complex']?

    it 'should use getter for read, not be stored internally', ->
      valStore['complex'] = 'poi'
      assert.equal complexObj.complex, 'poi'

