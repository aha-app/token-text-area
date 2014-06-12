class RenderedMultiSelect
  constructor: (@element, @options) ->
    return if @element.data("readonly") == "true"
    @inputContainer = @element.find(".rendered-multi-select-input")
    @input = @inputContainer.find(".editable-input")
    @createResultMenu()
    @registerEvents()
    @multiple = @element.data("multiple") == true
    @lastName = null
    @configureMultiple()
    @blurTimeout = null
    
  registerEvents: ->
    @element.on "keydown", ".editable-input", (event) =>
      @inputKeyDown(event)
    @element.on "keyup", ".editable-input", (event) =>
      @updateQuery(event)
    @element.on "blur", ".editable-input", (event) =>
      # Create any partially edited item.
      @createNewItem(@input.text())
      @blurTimeout = setTimeout =>
          @blurTimeout = null
          @input.val("")
          @resultMenu.fadeOut()
          @element.removeClass("rendered-multi-select-active")
        , 200
    @element.on "focus", ".editable-input", (event) =>
      clearTimeout @blurTimeout if @blurTimeout
      @element.addClass("rendered-multi-select-active")
      @lastName = null
      @updateQuery()
    @element.on "click", ".rendered-multi-select-menu li", (event) =>
      @addItem($(event.target))
      event.stopPropagation()
    @element.on "focus", ".rendered-multi-select-menu", (event) =>
      unless @input.is(":focus")
        clearTimeout @blurTimeout if @blurTimeout
        @input[0].focus() if @input[0]
    @element.on "mousedown", ".rendered-multi-select-menu", (event) =>
      false
    @element.on "click", ".rendered-multi-select-element b", (event) =>
      @deleteItem($(event.target).parent(".rendered-multi-select-element"))
      event.stopPropagation()
    @element.on "click", (event) =>
      # Focus the input when user clicks on the control.
      unless @input.is(":focus")
        clearTimeout @blurTimeout if @blurTimeout
        @input[0].focus() if @input[0]
      
    @element.on "change", (event) =>
      @configureMultiple()
      
  configureMultiple: ->
      # For non-multiple item controls hide input if an item exists.
      unless @multiple 
        if @element.find(".rendered-multi-select-element").length > 0
          @inputContainer.hide()
        else
          @inputContainer.show()
  
  createResultMenu: ->
    @resultMenu = $("<div class='rendered-multi-select-menu'><ul class='rendered-multi-select-results'></ul></div")
    @resultMenu.insertAfter(@input)
    @resultList = @resultMenu.find("ul")
    
  inputKeyDown: (event) ->
    switch event.keyCode
      when 13 # Enter
        if (result = @resultList.find("li").filter(".selected")).length != 0
          @addItem(result)
        else if @options.allowNew
          @createNewItem(@input.text())
      when 40 # Down arrow
        @selectNextResult(1)
      when 38 # Up arrow
        @selectNextResult(-1)
      when 8 # Backspace
        if @input.text().length > 0
          return
        else
          @deleteLastItem()
      else
        # Perform the default.
        return
    event.stopPropagation()
    event.preventDefault()

  clearInput: ->
    @lastName = null
    @input.text("")
    @resultMenu.hide()
    
  createNewItem: (name) ->
    name = $.trim(name)
    return if name.length == 0
    return if @itemExists(name)
    if @options.onCreateItem
      return unless name = @options.onCreateItem(name)
    @addItemRow(name)
    @clearInput()
    @updateQuery()
  
  deleteLastItem: ->
    lastItem = @element.find(".rendered-multi-select-element").last()
    return if lastItem.length == 0
    @deleteItem(lastItem)
    @lastName = null
    @updateQuery()
    
  deleteItem: (item) ->
    item.remove()
    if @options.onDeleteItem
      @options.onDeleteItem(item.attr("data-id"))
    @element.trigger("change")
   
  updateQuery: ->
    q = $.trim(@input.text())
    return if @lastName == q
    @lastName = q
    if @options.onQuery
      @options.onQuery q, (results) =>
        @showQueryResults(results)
  
  showQueryResults: (results) ->
    @resultList.empty()
    # Compute existing items so we can remove duplicates.
    existingIds = @existingIds()
    existingNames = @existingNames()
    resultAdded = false
    for result in results
      if $.inArray(result.id, existingIds) != -1 or $.inArray(result.name, existingNames) != -1
        continue
      @resultList.append("<li data-id='#{result.id}'>#{result.name}</li>")
      resultAdded = true
    if resultAdded
      # Only if we have focus.
      @resultMenu.show() if $(@input).is(":focus")
    else
      @resultMenu.hide()
    
  addItem: (result) ->
    id = result.attr("data-id")
    name = result.html()
    @addItemRow(name, id)
    if @options.onAddItem
      @options.onAddItem(id, name)
    @resultMenu.hide()
    @clearInput()
    @updateQuery()
  
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
    
  addItemRow: (name, id) ->
    if @options.onStyleItem
      style = @options.onStyleItem(name)
    else
      style = ""
    row = $("<li class='rendered-multi-select-element' data-id='#{id}' style='#{style}'></li>")
    row.html(name)
    row.append("<b>&times;</b>")
    @inputContainer.before(row)  
    @element.trigger("change")
    
  itemExists: (name) ->
    $.inArray(name, @existingNames()) != -1
  
  existingNames: ->
    @element.find(".rendered-multi-select-element")
      .map (index, element) ->
        $(element).text().slice(0,-1)
      .get()
      
  existingIds: ->
    @element.find(".rendered-multi-select-element")
      .map (index, element) ->
        $(element).attr("data-id")
      .get()
      
$.fn.renderedMultiSelect = (options, args...) ->
  @each ->
    $this = $(this)
    data = $this.data('plugin_renderedMultiSelect')

    if !data
      $this.data 'plugin_renderedMultiSelect', (data = new RenderedMultiSelect( $this, options))
    if typeof options == 'string'
      data[options].apply(data, args)

