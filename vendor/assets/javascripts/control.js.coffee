class TokenTextArea
  WORD_REGEX: /[a-z]+$/i

  SUCCESS_COLOR: '#64b80b;'
  ERROR_COLOR: '#b94a48;'
  NEUTRAL_COLOR: '#E0E0E0;'

  SUCCESS_MSG: 'Valid equation'
  ERROR_MSG: 'Syntax error in equation'
  CHECKING_MSG: 'Checking equation...'

  constructor: (@element, @options = {}) ->
    # Return if readonly (display) mode.
    return if @element.data("readonly") is true

    # Remove noborder class so highlighting works correctly.
    @element.removeClass("noborder")

    # Find input, set editable, don't allow tokens to be edited.
    @input = @element.find(".token-text-area-input")
    @input.attr "contenteditable", "true"
    @input.find(".token").attr("contenteditable", "false")

    # Ensure whitespace is correct.
    @fixWhitespace()

    # Ensure there's a space so the caret works at the end of input.
    @input.append('&nbsp;') unless @input.html().substr(-6) == '&nbsp;'

    # Create and store error message box, initialized to valid.
    @msg = $('<div style="margin-top: 5px; font-size: 12px; line-height: 16px;" class="token-text-area-msg"></div>')
    @element.after @msg
    @showSuccess()

    # Create instance variables.
    @resultMenu = null
    @resultList = null
    @word = null
    @range = null
    @typingTimer = null

    # Create the result menu.
    @createResultMenu()

    # Bind all handlers.
    @registerEvents()

  registerEvents: ->
    @input.on "keyup", =>

      clearTimeout(@typingTimer) unless @typingTimer is null
      @typingTimer = setTimeout( =>
        # Store selected range (used to recover position when autocomplete menu is clicked).
        @range = @getRange()

        # Open autocomplete menu if the user has typed letters.
        @checkAutocomplete()

        # Spans lose contenteditable attr when pasted. (!?)
        @input.find(".token").attr("contenteditable", "false")

        # Re-check validity of equation.
        @checkEquation()
      , 250)

    @input.on "keydown", (event) =>
      clearTimeout(@typingTimer) unless @typingTimer is null
      @showChecking() unless @isArrow(event.which)

      switch event.which
        when 13 # Enter
          @kill(event)
          if (result = @resultList.find("li").filter(".selected")).length != 0
            @addItem(result)
          else if @resultList.find("li").length == 1
            @addItem(@resultList.find("li").first())

        when 40 # Down arrow
          if @resultList.find("li").length > 0
            @kill(event)
            @selectNextResult(1)

        when 38 # Up arrow
          if @resultList.find("li").length > 0
            @kill(event)
            @selectNextResult(-1)

    @input.on "click", (event) =>
      # When the user clicks into the editor, check if they have clicked on a partial token to be completed.
      @checkAutocomplete()

      # Append a space so the caret blinks, if the input is empty.
      @input.append('&nbsp;') if @input.text().length is 0

    @input.on "blur", (event) =>
      # When the user clicks out of the editor, wait a tick to get the active item- if they did not click on the
      # autocomplete menu, close it.
      setTimeout( =>
        @closeAutocomplete() unless @resultMenu.is(":active")
      )

  kill: (event) ->
    event.stopPropagation()
    event.preventDefault()

  checkAutocomplete: ->
    # Open autocomplete menu if the user has typed letters.
    wordReg = @getWord().match @WORD_REGEX
    if wordReg is null
      @closeAutocomplete()
    else
      @word = wordReg
      @openAutocomplete()

  openAutocomplete: ->
    # Query server for autocomplete suggestions.
    if @options.onQuery
      @options.onQuery @word[0], (results) =>
        # Save currently selected suggestion to re-higlight it.
        selected = @resultList.find(".selected")
        @closeAutocomplete()
        
        # Populate results list.
        for result in results
          @resultList.append("<li data-id='#{result.id}'>#{result.name}</li>")

        # Re-select previously selected suggestion.
        $("li[data-id=" + selected.attr("data-id") + "]").addClass("selected") unless selected is null

        # Position result menu.
        @resultMenu.css('left', $(".token-text-area-input").position().left)
        @resultMenu.css('top', $(".token-text-area-input").position().top + $(".token-text-area-input").height() + 12)

        # Display suggestions and bind click event if we have focus.
        if $(@input).is(":focus") and @resultList.find("li").length > 0
          @resultMenu.css("display", "inline-block")
          @element.off "click", ".token-text-area-menu li"
          @element.on "click", ".token-text-area-menu li", (event) =>
            @addItem($(event.target))
            @kill(event)
        else
          @resultMenu.hide()

  closeAutocomplete: ->
    # Empty and hide autocomplete menu.
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
    return unless id

    # Create new token.
    name = result.html()
    token = '<span class="token" contenteditable="false" data-id="' + id + '">' + name + '</span>'
    
    # Re-place the caret in the editor (necessary if the user clicked on the autocomplete menu).
    sel = window.getSelection()
    sel.removeAllRanges()
    sel.addRange(@range)

    # Sanity check.
    return unless sel.getRangeAt and sel.rangeCount

    # Set range to metric name fragment.
    @range.setStart(@range.startContainer, @range.endOffset - @word[0].length)
    @range.deleteContents()

    # Create and insert new token.
    node = document.createElement('span')
    node.className = 'token'
    node.contentEditable = false
    node.setAttribute('data-id', id)
    node.innerHTML = name
    @range.insertNode(node)

    # Set selection range (i.e. caret position) to new token.
    range = @range.cloneRange()
    range.setStartAfter(node)
    range.collapse(true)
    sel.removeAllRanges()
    sel.addRange(range)

    # Ensure there's a space so the caret works at the end of input.
    @input.append('&nbsp;') unless @input.html().substr(-6) == '&nbsp;'

    # Close menu and reset.
    @closeAutocomplete()
    @range = null
    @word = null
    @resultList.html ''
    @checkEquation()

    return false

  checkEquation: ->
    # Remove any other elements they may have pasted in.
    @input.children(':not(.token)').each ->
      $(this).replaceWith($(this).html())
    @input.find('br').remove()

    # Replace tokens with #id#.
    equation = @fixHtmlTags(@input.html())

    # Turn equation into jQuery object and replace each token with its data-id.
    equation = $('<p>' + equation + '</p>')
    equation.children('.token').each ->
      $(this).replaceWith('#' + $(this).data('id') + '#')
    equation = equation.text()
    
    # Check with server to find if expression is valid.
    if @options.onChange
      @options.onChange equation, (valid) =>
        if valid
          @showSuccess()
        else
          @showError()

  isArrow: (code) ->
    $.inArray(code, [37, 38, 39, 40]) != -1

  getRange: ->
    # Return currently selected range.
    if window.getSelection and window.getSelection().rangeCount > 0
      range = window.getSelection().getRangeAt(0).cloneRange()
    else
      range = document.selection.createRange()
    range.collapse(true)
    range

  getWord: ->
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

  fixHtmlTags: (string) ->
    string = string.replace(/&nbsp;/g, '')
    string = string.replace(/&gt;/g, '>')
    string = string.replace(/&lt;/g, '<')

  fixWhitespace: ->
    html = @fixHtmlTags(@input.html())
    html = html.replace(/&nbsp;/g, ' ')
    html = html.replace(/[\s]+/g, ' ')
    @input.html(html)

  showSuccess: ->
    @element.removeClass "invalid"
    @element.removeClass "maybevalid"
    @element.addClass "valid"
    @msg.html(@SUCCESS_MSG)
    @msg.css('color', @SUCCESS_COLOR)

  showError: ->
    @element.removeClass "valid"
    @element.removeClass "maybevalid"
    @element.addClass "invalid"
    @msg.html(@ERROR_MSG)
    @msg.css('color', @ERROR_COLOR)

  showChecking: ->
    @element.removeClass "valid"
    @element.removeClass "invalid"
    @element.addClass "maybevalid"
    @msg.html(@CHECKING_MSG)
    @msg.css('color', @NEUTRAL_COLOR)
      
$.fn.tokenTextArea = (options, args...) ->
  @each ->
    $this = $(this)
    data = $this.data('plugin_tokenTextArea')

    if !data
      $this.data 'plugin_tokenTextArea', (data = new TokenTextArea( $this, options))
    
    if typeof options is 'string'
      data[options].apply(data, args)

