module TokenTextArea
  module TokenTextAreaHelpers
    
    def rendered_multi_select(elements, options = {})
      options.symbolize_keys!

      readonly = !!options[:readonly]
      multiple = options[:multiple] != false
      html_options = options[:html] || {}
      tag_options = html_options.merge(
        :class => "rendered-multi-select #{html_options[:class]} #{'editable' unless readonly}",
        "data-readonly" => readonly,
        "data-multiple" => multiple)
      
      if !!options[:readonly]
        close_box = ""
      else
        close_box = "<b>&times;</b>"
      end
      
      container_tag = options[:container_tag] || :ul
      element_tag = options[:element_tag] || :li
      
      content_tag(container_tag, tag_options) do
        s = ""
        elements.each do |element|
          text, value = option_text_and_value(element).map { |item| item.to_s }
          if block_given?
            style = yield text
          else
            style = nil
          end
          
          s << content_tag(element_tag, :class => "rendered-multi-select-element", "data-id" => value, :style => style) do
            "#{h(text)}#{close_box}".html_safe
          end
        end
        
        if ! !!options[:readonly]
          input = content_tag(element_tag, :class => "rendered-multi-select-input", :style => ((!multiple && elements.any?) ? 'display: none;' : '')) do
            content_tag(:div, "", :contenteditable => "true", :placeholder => options[:placeholder], :class => "editable-input")
          end
        else
          s << "<li>&nbsp;</li>" if elements.empty?
          input = ""
        end
        
        s.html_safe + input
      end
    end
    
    
    
  private
    def option_text_and_value(option)
      # Options are [text, value] pairs or strings used for both.
      case
      when Array === option
        option = option.reject { |e| Hash === e }
        [option.first, option.last]
      when !option.is_a?(String) && option.respond_to?(:first) && option.respond_to?(:last)
        [option.first, option.last]
      else
        [option, option]
      end
    end
  end
end