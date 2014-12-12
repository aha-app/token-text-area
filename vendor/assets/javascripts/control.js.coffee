class TokenTextArea

  constructor: (@element, @options) ->
    return if @element.data("readonly") is "true"

    @element.attr "contenteditable", "true"

    @autocompletes = JSON.parse @element.attr("data-autocomplete")
    @input = $ "<input>"
    @input.css "display", "none"
    
    @element.append @input

    names = @autocompletes.map (elem) ->
      elem[0]

    @input.typeahead(
      hint: true
      highlight: true
      minLength: 1
    ,
      name: 'states'
      local: names
      source: @substringMatcher(names)
    )

    @element.on "click", (event) =>
      target = $(event.target)

      return if target.is 'p'

      @element.focus()

      # If a button was not clicked, set index normally
      if @element[0] is target[0]
        @clearText()
      # Else set to nearest space
      else
        @setFocus target.index() + 1

    @element.on "blur", =>
      @clearText()

    @element.on "keypress", (event) =>
      # Don't allow carriage returns.
      return false if event.which is 13

    @element.on "keyup", (event) =>
      # Update element if input is an arrow key (movement) or space (end of word).
      if @isArrow(event.which)
        @clearText()
        @closeAutocomplete()
      else
        @addToken()

  setFocus: (index) ->
    sel = window.getSelection()
    range = document.createRange()
    range.collapse(true)
    range.setStart(@element[0], index)
    sel.removeAllRanges()
    sel.addRange(range)

  addToken: ->
    # Get the word before the cursor.
    range = @getText()
    if range.match(/[a-z]+$/i) != null
      @openAutocomplete(range.trim())
    else if (reg = range.match(/[0-9]+(.[0-9]+)?[^0-9|.]$/i))
      val = reg[0]
      @add('num', val.substr(0, val.length - 1))
      if val.substr(val.length - 1).match(/[\+|\-|\*|\/|^|\(|\)]$/i)
        @add('sym', val.substr(val.length - 1))
        
    else if (reg = range.match(/[\+|\-|\*|\/|^|\(|\)]$/i))
      @add('sym', reg[0])

  add: (type, value, cb) ->
    # If number or symbol, simply add it
    if type is 'num' or type is 'sym'
      newToken = '<input type=button class="token-sym" value="' + value + '" />'

    # Check if word has autocomplete value
    else
      matches = @autocompletes.filter (ac) ->
        ac[0] is value
      ac = matches[0]
      newToken = '<input type=button data-id="' + ac[1] + '" class="token" value="' + ac[0] + '" />'

    # Update HTML
    unless newToken is null
      offset = @getOffset()
      @clearText()
      if offset is 0
        $(@element.children()[offset]).before newToken
        @setFocus 2
      else
        $(@element.children()[offset - 1]).after newToken
        @setFocus offset + 1

  openAutocomplete: (val) ->
    @input.typeahead 'val', val

    @element.find('.tt-suggestion').off 'click'
    @element.find('.tt-suggestion').on 'click', (e) =>
      @add 'token', $(e.currentTarget).text()

  closeAutocomplete: ->
    @input.typeahead 'close'

  isArrow: (keycode) ->
    $.inArray(keycode, [37, 38, 39, 40]) != -1

  isSpace: (keycode) ->
    keycode is 32

  getText: ->
    @element.contents().filter( ->
        this.nodeType is 3
    ).text()

  clearText: ->
    @element.contents().filter( ->
      this.nodeType is 3
    ).remove()

  getOffset: ->
    @element.contents().filter( ->
      this.nodeType is 3
    ).index()

  substringMatcher: (strs) ->
    return (q, cb) ->
      matches = []
      substrRegex = new RegExp(q, 'i')
      $.each(strs, (i, str) ->
        if substrRegex.test(str)
          matches.push( value: str )
      )
      cb(matches)
      
$.fn.tokenTextArea = (options, args...) ->
  @each ->
    $this = $(this)
    data = $this.data('plugin_tokenTextArea')

    if !data
      $this.data 'plugin_tokenTextArea', (data = new TokenTextArea( $this, options))
    if typeof options is 'string'
      data[options].apply(data, args)

