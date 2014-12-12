module TokenTextArea
  module TokenTextAreaHelpers
    
    def token_text_area(elements, options = {})
      options.symbolize_keys!

      readonly = !!options[:readonly]
      html_options = options[:html] || {}
      data_options = options[:data] || {}
      data_options.merge!({readonly: readonly})
      tag_options = html_options.merge(
        class: "token-text-area #{html_options[:class]}",
        data: data_options
      )
      
      container_tag = options[:container_tag] || :div
      
      content_tag(container_tag, tag_options) do
        s = ""
        elements.each do |element|
          text, value = editor_item(element)
          if value.nil?
            s << content_tag(:input, type: :button, class: 'token-sym', value: text.html_safe) do; end
          else
            if block_given?
              style = yield text
            else
              style = nil
            end
            
            s << content_tag(:input, type: :button, class: 'token', data: { id: value }, style: style, value: text.html_safe) do; end
          end
        end
        
        s.html_safe
      end
    end
    
  private
    def editor_item(item)
      # Items are [text, id] pairs (i.e. tokens), numbers, or mathematical operators.
      case
      when !item.is_a?(String) && item.respond_to?(:first) && item.respond_to?(:last)
        [item.first, item.last]
      else
        [item, nil]
      end
    end
  end
end