class TokenTextArea

  constructor: (@element, @options) ->
    return if @element.data("readonly") is "true"

    @element.attr "contenteditable", "true"

    @registerEvents()

  registerEvents: ->
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

  createResultMenu: ->
    @resultMenu = $("<div class='token-text-area-menu'><ul class='token-text-area-results'></ul></div")
    @resultMenu.insertAfter(@input)
    @resultList = @resultMenu.find("ul")

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
      q = $.trim(range)
      if @options.onQuery
        @options.onQuery q, (results) =>
          @showQueryResults(results)
    else if (reg = range.match(/[0-9]+(.[0-9]+)?[^0-9|.]$/i))
      val = reg[0]
      @add('num', val.substr(0, val.length - 1))
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

  showQueryResults: (results) =>
    console.log results
    @resultList.empty()

    @resultList.append("<li>#{result}</li>") for result in results

    @resultMenu.show()

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

