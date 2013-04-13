assert = chai.assert

describe "Router", ->
  describe "regex", ->
    it 'should find project id from path', ->
      path = "/edit/1234-abcd-5678-abcd0987"
      match = editRegex.exec path
      console.log "Match", match
      assert.ok match
      assert.equal match[1], "1234-abcd-5678-abcd0987"

    it 'should find file id from path', ->
      path = "/edit/1234-abcd-5678-abcd0987/e9ee458f-7e0b-4a57-b471"
      match = editRegex.exec path
      assert.ok match
      assert.equal match[1], "1234-abcd-5678-abcd0987"
      assert.equal match[2], "e9ee458f-7e0b-4a57-b471"

    it 'should find line number from path', ->
      path = "/edit/1234-abcd-5678-abcd0987/e9ee458f-7e0b-4a57-b471#L77"
      match = editRegex.exec path
      assert.ok match
      assert.equal match[1], "1234-abcd-5678-abcd0987"
      assert.equal match[2], "e9ee458f-7e0b-4a57-b471"
      assert.equal match[3], "77"
        