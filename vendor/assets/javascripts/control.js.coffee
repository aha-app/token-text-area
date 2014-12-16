class TokenTextArea
  TOKEN_REGEX: /<span class="token" data-id="[0-9]+" contenteditable="false">.+<\/span>/i
  ID_REGEX: /data-id="[0-9]+"/i
  WORD_REGEX: /[a-z]+$/i

  constructor: (@element, @options = {}) ->
    # Remove outline and return if readonly (display) mode.
    if @element.data("readonly") is true
      @element.addClass "noborder"
      return

    @input = @element.find(".token-text-area-input")

    @input.attr "contenteditable", "true"

    @typingTimer = null
    @resultMenu = null
    @resultList = null
    @word = null

    @createResultMenu()

    @registerEvents()

    @forceSpace()
    @noNewLines()

  registerEvents: ->
    @element.on "click", ".token-text-area-menu li", (event) =>
      @addItem($(event.target))
      return false

    @input.on "keyup paste input", (event) =>
      # Open autocomplete menu if it's a word.
      wordReg = @getSelection().match @WORD_REGEX
      if wordReg is null
        @closeAutocomplete()
      else
        @word = wordReg
        @openAutocomplete()

      # Spans lose contenteditable attr when pasted. (!?)
      @input.find(".token").attr("contenteditable", "false")

      unless @isArrow(event.which)
        @element.removeClass "valid"
        @element.removeClass "invalid"
        @element.addClass "maybevalid"

        clearTimeout(@typingTimer) unless @typingTimer is null
        @typingTimer = setTimeout( =>
          @checkEquation()
        , 100)

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

  openAutocomplete: () ->
    if @options.onQuery
      @options.onQuery @word[0], (results) =>
        selected = @resultList.find(".selected")
        @closeAutocomplete()
        
        for result in results
          @resultList.append("<li data-id='#{result.id}'>#{result.name}</li>")

        $("li[data-id=" + selected.attr("data-id") + "]").addClass("selected") unless selected is null

        if $(@input).is(":focus") and @resultList.find("li").length > 0
          @resultMenu.css("display", "inline-block") 
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
    id = result.attr("data-id")
    return false unless id

    # Replace typing with token.
    name = result.html()
    token = '<span class="token" contenteditable="false" data-id="' + id + '">' + name + '</span>'
    @input.html(@input.html().substr(0, @word.index) + token + @input.html().substr(@word.index + @word[0].length))

    # Close menu and reset.
    @closeAutocomplete()
    @word = null
    @resultList.html ''
    @checkEquation()
    @forceSpace()
    @noNewLines()

  checkEquation: ->
    # Replace tokens with #id#.
    equation = @input.html().replace(/&nbsp;/g, ' ')
    while (token = equation.match(@TOKEN_REGEX)) != null
      idReg = token[0].match(@ID_REGEX)
      id = idReg[0].replace('data-id="', '').replace('"', '')
      equation = equation.replace(@TOKEN_REGEX, '#' + id + '#')
    
    # Check with server to find if expression is valid.
    if @options.onChange
      @options.onChange equation, (results) =>
        if results.valid
          @element.removeClass "maybevalid"
          @element.removeClass "invalid"
          @element.addClass "valid"
        else
          @element.removeClass "maybevalid"
          @element.removeClass "valid"
          @element.addClass "invalid"

  existingNames: ->
    @element.find(".token-text-area-results li")
      .map (index, element) ->
        $(element).html()
      .get()
      
  existingIds: ->
    @element.find(".token-text-area-results li")
      .map (index, element) ->
        $(element).attr("data-id")
      .get()

  isArrow: (code) ->
    $.inArray(code, [37, 38, 39, 40]) != -1

  getCaretPos: ->
    if window.getSelection and window.getSelection().rangeCount > 0
      range = window.getSelection().getRangeAt(0).cloneRange()
    else
      range = document.selection.createRange()
    range.collapse(true)
    range.setStart(@element[0], 0)
    range.toString().length

  getSelection: ->
    caretPos = origCaretPos = @getCaretPos()

    # Remove each token in range and remove them from the caret position.
    # Otherwise, autocomplete suggestions will include existing tokens.
    html = $('<p>' + @input.html() + '</p>')

    while html.find('.token').length > 0
      token = $(html.find('.token').first())
      break unless @input.text().indexOf(token.text()) < origCaretPos
      caretPos -= token.text().length
      newContents = html.contents().not(token)
      html.empty().append(newContents)

    html.text().substr(0, caretPos)

  forceSpace: ->
    html = @input.html()
    @input.append('&nbsp;') unless html.substr(html.length - 6) is '&nbsp;'

  noNewLines: ->
    @input.html(@input.html().replace(/(<br>|\n)/g, ''))
      
$.fn.tokenTextArea = (options, args...) ->
  @each ->
    $this = $(this)
    data = $this.data('plugin_tokenTextArea')

    if !data
      $this.data 'plugin_tokenTextArea', (data = new TokenTextArea( $this, options))
    if typeof options is 'string'
      data[options].apply(data, args)

