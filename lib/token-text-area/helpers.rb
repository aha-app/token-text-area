module TokenTextArea
  module TokenTextAreaHelpers
    
    def token_text_area(equation, metrics, values, options = {})
      options.symbolize_keys!

      readonly = !!options[:readonly]
      html_options = options[:html] || {}
      data_options = options[:data] || {}
      data_options.merge!({readonly: readonly})
      tag_options = html_options.merge(
        class: "token-text-area valid #{html_options[:class]}",
        data: data_options
      )
      
      container_tag = options[:container_tag] || :div
      
      content_tag(container_tag, tag_options) do
        content_tag(:div, class: 'token-text-area-input') do
          unless equation.nil?
            equation.gsub!(/#[0-9]+#/) do 
              cur_match = Regexp.last_match.to_s
              metric = metrics.detect{ |m| m[:id] == cur_match.gsub('#','').to_i }
              content_tag(:span, class: 'token', data: { id: metric[:id] }, contenteditable: 'false') do
                label = metric[:name]
                label += "&nbsp;<b>#{values.detect{ |v| v[:metric_id] == metric[:id] }[:value].to_s}</b>" if values
                label.html_safe
              end
            end
            equation.html_safe
          end
        end
      end
    end
  end
end