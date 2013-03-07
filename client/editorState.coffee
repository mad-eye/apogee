#TODO: This is just the bone-headed extraction of code from edit.coffee.
#We should refactor it so that it doesn't have knowlege of DOM ids/etc.

#Takes httpResponse
handleNetworkError = (error, response) ->
  err = response.content?.error ? error
  console.error "Network Error:", err
  Metrics.add
    level:'error'
    message:'networkError'
    error: err
  transitoryIssues.set 'networkIssues', 10*1000

# Must set editorState.file for fetchBody or save to work.
class EditorState
  constructor: (@editorId)->
    @contexts = new Meteor.deps._ContextSet()

  getEditor: ->
    editor = ace.edit @editorId
    editor.setTheme "ace/theme/eclipse"
    return editor

  getEditorBody : ->
    @getEditor()?.getValue()

  getFileUrl : ->
    Meteor.settings.public.azkabanUrl + "/project/#{Projects.findOne()._id}/file/#{@file._id}"

  setPath: (filePath) ->
    return if filePath == @filePath
    @filePath = filePath
    @contexts.invalidateAll()

  setLine: (@lineNumber) ->

  getPath: () ->
    @contexts.addCurrentContext()
    return @filePath

  revertFile: (callback) ->
    Metrics.add
      message:'revertFile'
      fileId: @file?._id
      filePath: @file?.path
    @doc.detach_ace()
    @getEditor().setValue("")
    Meteor.http.get "#{@getFileUrl()}?reset=true", (error,response) =>
      if error
        handleNetworkError error, response
        callback(error)
      @file.modified = false
      @file.save()
      callback()
      Meteor.setTimeout =>
        @doc.attach_ace(@getEditor())
        @getEditor().navigateFileStart()
      ,0

  loadFile: (file) ->
    #console.log "Loading file", file
    @file = file
    Metrics.add
      message:'loadFile'
      fileId: @file?._id
      filePath: @file?.path
    sharejs.open file._id, "text2", "#{Meteor.settings.public.bolideUrl}/channel", (error, doc) =>
      try
        handleShareError error if error?
        editor = @getEditor()
        @doc?.detach_ace?()
        @doc = doc
        #TODO: Extract this into its own autorun block
        if mode = file.aceMode()
          Mode = undefined
          try
            Mode = require("ace/mode/#{mode}").Mode
            editor.getSession().setMode(new Mode())
          catch e
            jQuery.getScript "/ace/mode-#{mode}.js", =>
              Mode = require("ace/mode/#{mode}").Mode
              editor.getSession().setMode(new Mode())

        unless doc.version?
          #This seems to be a spurious case when the file is opened twice quickly.
          Metrics.add
            level:'warn'
            message:'shareJsError'
            fileId: @file._id
            filePath: @file?.path
            error: 'Found null doc version'
          console.error "Found null doc version for file #{@file._id}"
          return
        if doc.version > 0
          unless doc.editorAttached
            doc.attach_ace editor
          else
            Metrics.add
              level:'warn'
              message:'shareJsError'
              fileId: @file._id
              filePath: @file?.path
              error: 'Found null doc version'
            console.error "EDITOR ALREADY ATTACHED"
          doc.on 'change', (op) ->
            file.update {modified: true}
          doc.on 'warn', (data) ->
            Metrics.add
              level:'warn'
              message:'shareJsError'
              fileId: @file._id
              filePath: @file?.path
              error: data

          editor.navigateFileStart() unless doc.cursor
          doc.emit "cursors"
        else
          Session.set "editorIsLoading", true
          #TODO figure out why this sometimes gets stuck on..
          #editor.setReadOnly true
          Meteor.http.get @getFileUrl(), timeout:5*1000, (error,response) =>
            if error
              handleNetworkError error, response
            else
              if doc == @doc #Safety for multiple loadFiles running simultaneously
                Session.set "editorIsLoading", false
                editor = @getEditor()
                doc.attach_ace editor
                editor.navigateFileStart() unless doc.cursor
                doc.on 'change', (op) ->
                  file.update {modified: true}
                  doc.emit "cursors" #TODO: This should be handled in ShareJS
                doc.on 'warn', (data) ->
                  Metrics.add
                    level:'warn'
                    message:'shareJsError'
                    fileId: @file._id
                    filePath: @file?.path
                    error: data
      catch e
        #TODO: Handle this better.
        Metrics.add
          level:'error'
          message:'shareJsError'
          fileId: @file._id
          filePath: @file?.path
          error: e.message
        console.error e




  #callback: (err) ->
  save : (callback) ->
    #console.log "Saving file #{@file?._id}"
    Metrics.add
      message:'saveFile'
      fileId: @file?._id
      filePath: @file?.path #don't want reactivity
    self = this #The => doesn't work for some reason with the PUT callback.
    contents = @getEditorBody()
    file = @file
    return unless @file.modified
    Meteor.http.put @getFileUrl(), {
      data: {contents: contents}
      headers: {'Content-Type':'application/json'}
      timeout: 5*1000
    }, (error,response) ->
      if error
        handleNetworkError error, response
      else
        #XXX: Are we worried about race conditions if there were modifications after the save button was pressed?
        file.update {modified: false}
      callback(error)


