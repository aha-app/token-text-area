class TokenTextArea
  constructor: (@element, @options) ->
    return if @element.data("readonly") == "true"
    
    @element.attr('contenteditable', 'true')
    @element.on "keyup", (event) =>
      # Get the word before the cursor.
      word = @getWord()
      #if word and word.length > 0
      #  @options.tokens.
      
  getWord: ->
    sel = window.getSelection();
    if sel.rangeCount > 0
      range = sel.getRangeAt(0).cloneRange();
      range.collapse(true);
      range.setStart(@element[0], 0);
      range.toString().match(/[a-z]+$/i)[0]
      
$.fn.tokenTextArea = (options, args...) ->
  @each ->
    $this = $(this)
    data = $this.data('plugin_tokenTextArea')

    if !data
      $this.data 'plugin_tokenTextArea', (data = new TokenTextArea( $this, options))
    if typeof options == 'string'
      data[options].apply(data, args)

