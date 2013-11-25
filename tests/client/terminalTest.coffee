appendTerminalParent = (id)->

  $("""<h3>Terminal#{id}</h3><div id="#{id}" style="height:40px; width: 300px; position: relative; float: left; margin-right: 15px; margin-bottom: 30px; background-color: pink"></div> """).appendTo $("#tests")

randomId = () ->
  return Math.floor( Math.random() * 1000000 + 1)

Meteor.startup ->
  describe "METerminal", ->
    assert = chai.assert

    terminalParentId = "terminal#{randomId()}"
    terminalParentDiv = null
    meTerminal = null

    MockWindow = _.extend MicroEvent
    MockWindow.prototype.resize = ->

    mockTty =
      Window: MockWindow
      reset: ->
      disconnect: ->

    before ->
      appendTerminalParent terminalParentId

    it "should find the parent div", ->
      terminalParentDiv = $("#" + terminalParentId)[0]
      assert.isNotNull terminalParentDiv

    it "should be able to create an METerminal", ->
      meTerminal = new METerminal(mockTty)

    it "should allow a terminal to be attached to a div", ->
      meTerminal.create parent: terminalParentDiv

    it "should emit a focus event when the window is opened", (done)->
      listener =  ->
        meTerminal.removeListener "focus", listener
        done()
      meTerminal.on "focus", listener
      meTerminal.window.emit "open"
      

    it "should emit a focus when a tty window is focused", (done)->
      listener = ->
        meTerminal.removeListener "focus", listener
        done()
      meTerminal.on "focus", listener
      meTerminal.window.emit "focus"
