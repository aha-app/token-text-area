class TokenTextArea
  TOKEN_REGEX: /<span class="token" (contenteditable="false" data-id="[0-9]+"|data-id="[0-9]+" contenteditable="false")>[^<]+<\/span>/i
  ID_REGEX: /data-id="[0-9]+"/i
  WORD_REGEX: /[a-z]+$/i

  constructor: (@element, @options = {}) ->
    # Remove outline and return if readonly (display) mode.
    if @element.data("readonly") is true
      @element.addClass "noborder"
      return

    @input = @element.find(".token-text-area-input")

    @input.attr "contenteditable", "true"
    @input.find(".token").attr("contenteditable", "false")

    @element.after('<div style="color: #b94a48; padding-left: 80px; margin-top: 10px; font-size: 12px; line-height: 16px;">Syntax error in formula.</div>')
    @errorMsg = @element.next()
    @errorMsg.hide()

    @typingTimer = null
    @resultMenu = null
    @resultList = null
    @word = null
    @range = null

    @createResultMenu()

    @registerEvents()

  registerEvents: ->
    @input.on "keyup paste input", (event) =>
      @range = @getRange()

      @checkAutocomplete()

      # Spans lose contenteditable attr when pasted. (!?)
      @input.find(".token").attr("contenteditable", "false")

      unless @isArrow(event.which)
        @element.removeClass "valid"
        @element.removeClass "invalid"
        @element.addClass "maybevalid"
        @errorMsg.hide()

        clearTimeout(@typingTimer) unless @typingTimer is null
        @typingTimer = setTimeout( =>
          @checkEquation()
        , 100)

    @input.on "paste", (event) =>
      @input.html(@input.html().replace(/(<br>|\n)/g, ''))

    @input.on "keydown", (event) =>
      clearTimeout(@typingTimer) unless @typingTimer is null

      switch event.which
        when 13 # Enter
          if (result = @resultList.find("li").filter(".selected")).length != 0
            @addItem(result)
          else if @resultList.find("li").length == 1
            @addItem(@resultList.find("li").first())
          return false
        when 40 # Down arrow
          if @resultList.find("li").length > 0
            @selectNextResult(1)
            return false
          else
            return
        when 38 # Up arrow
          if @resultList.find("li").length > 0
            @selectNextResult(-1)
            return false
          else
            return

    @input.on "click", (event) =>
      @checkAutocomplete()

    @input.on "blur", (event) =>
      setTimeout( =>
        @resultMenu.hide() unless @resultMenu.is(":active")
      )

  checkAutocomplete: ->
    # Open autocomplete menu if it's a word.
    wordReg = @getSelection().match @WORD_REGEX
    if wordReg is null
      @closeAutocomplete()
    else
      @word = wordReg
      @openAutocomplete()

  openAutocomplete: ->
    if @options.onQuery
      @options.onQuery @word[0], (results) =>
        selected = @resultList.find(".selected")
        @closeAutocomplete()
        
        for result in results
          @resultList.append("<li data-id='#{result.id}'>#{result.name}</li>")

        $("li[data-id=" + selected.attr("data-id") + "]").addClass("selected") unless selected is null

        if $(@input).is(":focus") and @resultList.find("li").length > 0
          @resultMenu.css("display", "inline-block")
          @element.off "click", ".token-text-area-menu li"
          @element.on "click", ".token-text-area-menu li", (event) =>
            @addItem($(event.target))
            return false
        else
          @resultMenu.hide()

  closeAutocomplete: ->
    @resultList.empty()
    @resultMenu.hide()

  createResultMenu: ->
    @resultMenu = $("<div class='token-text-area-menu'><ul class='token-text-area-results'></ul></div")
    @element.append @resultMenu
    @resultList = @resultMenu.find "ul"

  selectNextResult: (offset) ->
    items = @resultList.find("li")
    currentIndex = items.index(items.filter(".selected"))
    items.removeClass("selected")
    currentIndex += offset
    if currentIndex >= items.length
      @resultList.find("li").first().addClass("selected")
    else if currentIndex < 0
      @resultList.find("li").last().addClass("selected")
    else
      $(items[currentIndex]).addClass("selected")

  addItem: (result) ->
    id = result.data('id')
    return false unless id

    # Create new token.
    name = result.html()
    token = '<span class="token" contenteditable="false" data-id="' + id + '">' + name + '</span>'
    
    # Re-place the caret (necessary if the user clicked on the autocomplete menu).
    sel = window.getSelection()
    sel.removeAllRanges()
    sel.addRange(@range)

    if (sel.getRangeAt && sel.rangeCount)
      # Set range to metric name fragment.
      @range.setStart(@range.startContainer, @range.endOffset - @word[0].length)
      @range.deleteContents()

      # Create and insert new token.
      node = document.createElement('span')
      node.className = 'token'
      node.contentEditable = false
      node.dataset.id = id
      node.innerHTML = name
      @range.insertNode(node)
      @range.insertNode(document.createTextNode(' '));

      # Set selection range (i.e. caret position) to new token.
      range = @range.cloneRange()
      range.setStartAfter(node)
      range.collapse(true)
      sel.removeAllRanges()
      sel.addRange(range)

    # Close menu and reset.
    @closeAutocomplete()
    @range = null
    @word = null
    @resultList.html ''
    @checkEquation()

  checkEquation: ->
    # Replace tokens with #id#.
    equation = @input.html().replace(/&nbsp;/g, ' ')
    while (token = equation.match(@TOKEN_REGEX)) != null
      idReg = token[0].match(@ID_REGEX)
      id = idReg[0].replace('data-id="', '').replace('"', '')
      equation = equation.replace(@TOKEN_REGEX, ' #' + id + '# ')
    
    # Check with server to find if expression is valid.
    if @options.onChange
      @options.onChange equation, (results) =>
        if results.valid
          @element.removeClass "maybevalid"
          @element.removeClass "invalid"
          @element.addClass "valid"
          @errorMsg.hide()
        else
          @element.removeClass "maybevalid"
          @element.removeClass "valid"
          @element.addClass "invalid"
          @errorMsg.show()

  isArrow: (code) ->
    $.inArray(code, [37, 38, 39, 40]) != -1

  getRange: ->
    if window.getSelection and window.getSelection().rangeCount > 0
      range = window.getSelection().getRangeAt(0).cloneRange()
    else
      range = document.selection.createRange()
    range.collapse(true)
    range

  getSelection: ->
    # Determine the length of text in the input.
    range = @getRange()
    range.setStart(@element[0], 0)
    caretPos = range.toString().length

    # Remove each token in range and deduct them from the caret position.
    # Otherwise, autocomplete suggestions will include existing tokens.
    html = $('<p>' + @input.html() + '</p>')

    while html.find('.token').length > 0
      token = $(html.find('.token').first())
      break unless html.text().indexOf(token.text()) < caretPos
      caretPos -= token.text().length
      newContents = html.contents().not(token)
      html.empty().append(newContents)

    html.text().substr(0, caretPos)
      
$.fn.tokenTextArea = (options, args...) ->
  @each ->
    $this = $(this)
    data = $this.data('plugin_tokenTextArea')

    if !data
      $this.data 'plugin_tokenTextArea', (data = new TokenTextArea( $this, options))
    if typeof options is 'string'
      data[options].apply(data, args)

