module TokenTextArea
  module TokenTextAreaHelpers

    def token_text_area(equation, variables, options = {})
      options.symbolize_keys!

      readonly = !!options[:readonly]
      html_options = options[:html] || {}
      data_options = options[:data] || {}
      data_options.merge!({readonly: readonly})
      tag_options = html_options.merge(
        class: "token-text-area noborder #{html_options[:class]}",
        data: data_options
      )

      container_tag = options[:container_tag] || :div

      content_tag(container_tag, tag_options) do
        content_tag(:div, class: 'token-text-area-input') do
          if equation.nil?
            ''
          else
            equation.gsub!(/#[0-9]+#/) do
              cur_match = Regexp.last_match.to_s
              variable = variables.detect{ |v| v[:id] == cur_match.gsub('#','').to_i }
              if variable
                content_tag(:span, class: 'token', data: { id: variable[:id] }) do
                  label = variable[:name]
                  label += "&nbsp;<b>#{variable[:value].to_s}</b>".html_safe if variable[:value]
                  label.html_safe
                end
              else
                ""
              end
            end
            equation.html_safe
          end
        end
      end
    end
  end
end
