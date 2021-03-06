Range = ace.require('ace/range').Range

class OperationalTransform
  constructor: (@options) ->
    _.extend @, Backbone.Events
    @editor = @options.editor
  
  setModel: (model) ->
    @off()
    @stopListening()
    @model = model
    
    snapshot = @model.get 'Snapshot'
    if snapshot
      @editor.editor.setValue snapshot, 1

    
    @listenTo model, 'message', @onmessage
    @listenTo model, 'close', =>
      @editor.editor.setValue ""
    @on 'insert', @oninsert
    @on 'remove', @onremove

  posToRange: (pos) =>
    lines = @editor.doc.getAllLines()

    row = 0
    for line, row in lines
      break if pos <= line.length

      # +1 for the newline.
      pos -= lines[row].length + 1

    row:row, column:pos
  

  onmessage: (data) =>
    @quiet = true
    snapshot = @model.get 'Snapshot'
    unless snapshot
      if data.Snapshot
        @editor.editor.setValue data.Snapshot
    if data.OpData
      old_cursor = @editor.editor.getCursorPosition()
      #@transformCursor old_cursor, data.OpData
      for ops in data.OpData
        for op in ops
          i = op.Insert
          d = op.Delete
          r = @posToRange op.Position
  
          if i
            @editor.doc.insert r, i
          if d
            range = Range.fromPoints r, @posToRange(op.Position + d.length)
            @editor.doc.remove range
    
    @quiet = false
    
  
  oninsert: (data) =>
    op =
      Insert: data.text
      Position: data.position
      Delete: ""

    unless @quiet
      @model.queue op


  onremove: (data) =>
    op =
      Insert: ""
      Position: data.position
      Delete: data.text

    unless @quiet
      @model.queue op

module.exports = OperationalTransform
