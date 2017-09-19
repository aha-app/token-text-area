class TokenTextArea
  WORD_REGEX: /[\s|\w]+$/i

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

    # Function to handle reactive updates.
    @update = ->
      @createResultMenu()
      @saveEquation()

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
      
        # Save equation.
        @saveEquation()
      , 250)

    @input.on "keydown", (event) =>
      clearTimeout(@typingTimer) unless @typingTimer is null

      switch event.which
        when 13 # Enter
          @kill(event)
          if (result = @resultList.find("li").filter(".selected")).length != 0
            @addItem(result)
          else if @resultList.find("li").length == 1
            @addItem(@resultList.find("li").first())

        when 32 # Space
          if @options.operators
            @range = @getRange()
            operator = @range.startContainer.data.trim() if @range.startContainer.data
            if operator && @options.operators.includes(operator)
              @word = [operator] #TODO: Make this not a hack
              @addItem($('<span data-id='+operator+'>'+operator+'</span>'), true)

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

    @input.on "blur", (event) =>
      # When the user clicks out of the editor, wait a tick to get the active item- if they did not click on the
      # autocomplete menu, close it.
      setTimeout( =>
        @closeAutocomplete() unless @resultMenu.is(":active")
      )

    @element.on "mousedown", ".token-text-area-menu li", (event) =>
      @addItem($(event.target))
      @kill(event)

  kill: (event) ->
    event.stopPropagation()
    event.preventDefault()

  checkAutocomplete: ->
    # Open autocomplete menu if the user has typed letters.
    wordReg = @getWord().match @WORD_REGEX
    if wordReg is null || wordReg[0].trim().length == 0
      @closeAutocomplete()
    else
      @word = wordReg
      @openAutocomplete()

  openAutocomplete: ->
    # Query server for autocomplete suggestions.
    if @options.onQuery
      @options.onQuery @word[0].trim(), (results) =>
        # Save currently selected suggestion to re-higlight it.
        selected = @resultList.find(".selected")
        @closeAutocomplete()
        
        # Populate results list.
        for result in results
          @resultList.append("<li data-id='#{result.id}' data-token-display-name='#{result.tokenDisplayName}'>#{result.name}</li>")

        # Re-select previously selected suggestion.
        $("li[data-id=" + selected.attr("data-id") + "]").addClass("selected") unless selected is null

        # Position result menu.
        @resultMenu.css('left', $(".token-text-area-input").position().left)
        @resultMenu.css('top', $(".token-text-area-input").position().top + $(".token-text-area-input").height() + 12)

        # Display suggestions and bind click event if we have focus.
        if $(@input).is(":focus") and @resultList.find("li").length > 0
          @resultMenu.css("display", "inline-block")
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

  # This is meant to be an external function used to add items to the DOM
  # item is an object of the form:
  # { id: 'xyz', name: 'the display name' }
  pushItem: (item) ->
    id = item.id
    name = item.name
    return unless id and name

    # token = '<span class="token" contenteditable="false" data-id="' + id + '">' + name + '</span>'
    node = document.createElement('span')
    node.className = 'token'
    node.contentEditable = false
    node.setAttribute('data-id', id)
    node.innerHTML = name
    @input.append(node)
    @input.append('&nbsp;')
    @saveEquation()

  removeItem: (id) ->
    @input.find("[data-id='#{id}']").remove()
    @saveEquation()

  fillFromEquation: (equation, items) ->
    html = equation.replace(/\#(\w+)\#/g, (dirtyId) ->
      id = dirtyId.replace(/\#/g, '')
      foundItem = items.filter( (item) -> item.id == id )[0]
      return '' unless foundItem
      name = foundItem.name
      return '&nbsp;<span class="token" contenteditable="false" data-id="' + id + '">' + name + '</span>&nbsp;'
    )
    if @options.operators
      for op in @options.operators
        html = html.split(op).join('&nbsp;<span contenteditable="false" class="operator">' + op + '</span>&nbsp;')

    @input.html( html )
    @saveEquation()


  addItem: (result, operator=false) ->
    id = result.data('id')
    return unless id

    tokenDisplayName = result.data('tokenDisplayName')

    # Create new token.
    name = tokenDisplayName || result.html()
    # token = '<span class="token" contenteditable="false" data-id="' + id + '">' + name + '</span>'
    
    # Re-place the caret in the editor (necessary if the user clicked on the autocomplete menu).
    sel = window.getSelection()
    sel.removeAllRanges()
    sel.addRange(@range)

    # Sanity check.
    return unless sel.getRangeAt and sel.rangeCount

    # Set range to metric name fragment.
    @range.setStart(@range.startContainer, @range.endOffset - @word[0].trim().length)
    @range.deleteContents()

    node = document.createElement('span')
    if operator
      # Create and insert new token.
      node.className = 'operator'
      node.contentEditable = false
      node.innerHTML = name
    else
      # Create and insert new token.
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
    @saveEquation()

    return false

  saveEquation: ->
    # Remove any other elements they may have pasted in.
    @input.children(':not(.token):not(.operator)').each ->
      $(this).replaceWith($(this).html())
    @input.find('br').remove()

    # Replace tokens with #id#.
    equation = @fixHtmlTags(@input.html())

    # Turn equation into jQuery object and replace each token with its data-id.
    equation = $('<p>' + equation + '</p>')
    equation.children('.token').each ->
      $(this).replaceWith('#' + $(this).data('id') + '#')

    # if @options.operators
    #   equation.children('.operator').each ->
    #     $(this).replaceWith('@' + $(this).text() + '@')

    equation = equation.text()
    
    # Check with server to find if expression is valid.
    @options.onChange(equation) if @options.onChange

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

    while html.find('.token, .operator').length > 0
      token = $(html.find('.token, .operator').first())
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
      
$.fn.tokenTextArea = (options, args...) ->
  @each ->
    $this = $(this)
    data = $this.data('plugin_tokenTextArea')

    $this.data('plugin_tokenTextArea', (data = new TokenTextArea( $this, options))) unless data
    
    if typeof options is 'string'
      data[options].apply(data, args)
