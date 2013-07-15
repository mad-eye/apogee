describe 'aceMode', ->
  assert = chai.assert

  assertCorrectMode = (filename, mode) ->
    f = new MadEye.File {path:filename, isDir:false}
    assert.equal f.aceMode, mode, "Incorrect mode for #{filename}"

  describe 'from extension', ->
    it 'should calculate easy cases correctly', ->
      assertCorrectMode 'foo.js', 'javascript'
      assertCorrectMode 'foo.coffee', 'coffee'
      assertCorrectMode 'whatever.java', 'java'
      assertCorrectMode 'foo.html', 'html'
      assertCorrectMode 'var.css', 'css'

    it 'should get c/c++ correctly', ->
      assertCorrectMode 'first.c', 'c_cpp'
      assertCorrectMode 'second.cpp', 'c_cpp'
      assertCorrectMode 'third.cc', 'c_cpp'
      assertCorrectMode 'ff.cxx', 'c_cpp'
  
  describe 'from filename', ->
    it 'should get makefile from Makefiles', ->
      assertCorrectMode 'Makefile', 'makefile'
    it 'should get coffee from Cakefiles', ->
      assertCorrectMode 'Cakefile', 'coffee'
    it 'should get ruby from Rakefiles', ->
      assertCorrectMode 'Rakefile', 'ruby'

  #TODO: Set the editor body and file and check Session.get 'syntaxMode', but that requires more time than i have right now.
  describe 'from shebang', ->
    it 'should get null from "random text"'
    it 'should get null from "#!"'
    it 'should get sh from "#! /bin/env sh -x"'
    it 'should get sh from "#! /bin/bash"'
    it 'should get python from "#!/usr/bin/python"'
