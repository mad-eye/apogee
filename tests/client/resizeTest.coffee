
describe 'Resizer', ->
  assert = chai.assert

  describe 'maxTerminalHeight', ->
    resizer = null
    chromeHeight = 600
    chromeWidth = 400

    beforeEach ->
      resizer = new Resizer()
      resizer.chromeHeight = chromeHeight
      resizer.chromeWidth = chromeWidth

    it 'should be chromeHeight/3', ->
      assert.equal resizer.maxTerminalHeight, chromeHeight/3

  describe 'maxTerminalWidth', ->
    resizer = null
    chromeHeight = 600
    chromeWidth = 400

    beforeEach ->
      resizer = new Resizer()
      resizer.chromeHeight = chromeHeight
      resizer.chromeWidth = chromeWidth

    it 'should be chromeWidth', ->
      assert.equal resizer.maxTerminalWidth, chromeWidth


  describe 'terminalHeight', ->
    resizer = null
    chromeHeight = 600
    chromeWidth = 400

    beforeEach ->
      resizer = new Resizer()
      resizer.chromeHeight = chromeHeight
      resizer.chromeWidth = chromeWidth

    it 'should be 0 when !terminalEnabled', ->
      resizer.terminalEnabled = false
      assert.equal resizer.terminalHeight, 0

    it 'should be 0 when !terminalShown', ->
      resizer.terminalEnabled = true
      resizer.terminalShown = false
      assert.equal resizer.terminalHeight, 0

    it 'should be 20 when terminalEnabled and terminalShown and !terminalOpened', ->
      resizer.terminalEnabled = true
      resizer.terminalShown = true
      resizer.terminalOpened = false
      assert.equal resizer.terminalHeight, 20

    it 'should be maxTerminaHeight when terminalOpened', ->
      resizer.terminalEnabled = true
      resizer.terminalShown = true
      resizer.terminalOpened = true
      assert.equal resizer.terminalHeight, resizer.maxTerminalHeight

  describe 'terminalHeight/Width with other sessions', ->
    resizer = null
    chromeHeight = 600
    chromeWidth = 400

    beforeEach ->
      resizer = new Resizer()
      resizer.chromeHeight = chromeHeight
      resizer.chromeWidth = chromeWidth
      resizer.terminalEnabled = true
      resizer.terminalShown = true
      resizer.terminalOpened = true

    it 'should be restricted by smaller terminals', ->
      resizer.otherTerminalSizes = [
        {height: 150, width: 500},
        {height: 200, width: 350},
        {height: 300, width: 600}
      ]
      assert.equal resizer.terminalHeight, 150
      assert.equal resizer.terminalWidth, 350

    it 'should be its max if other terminals are bigger', ->
      resizer.otherTerminalSizes = [
        {height: 210, width: 450},
        {height: 300, width: 600}
      ]
      assert.equal resizer.terminalHeight, 200
      assert.equal resizer.terminalWidth, 400


