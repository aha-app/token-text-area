module TokenTextArea
  class Engine < ::Rails::Engine
    
    initializer "token-text-area" do
      ActionView::Base.send(:include, TokenTextArea::TokenTextAreaHelpers)
    end
    
  end
end