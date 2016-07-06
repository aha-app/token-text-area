$:.push File.expand_path("../lib", __FILE__)
require "token-text-area/version"

Gem::Specification.new do |s|
  s.name        = "token-text-area"
  s.version     = TokenTextArea::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["k1w1"]
  s.email       = ["k1w1@k1w1.org"]
  s.homepage    = "http://github.com/k1w1/token-text-area"
  s.summary     = %q{todo}
  s.description = %q{todo}

  s.files         = Dir["vendor/assets/javascripts/*.js.coffee", "vendor/assets/stylesheets/*.css.less", "lib/*" "README.md", "MIT-LICENSE"]
  s.require_paths = ["lib"]

  s.add_dependency 'rails'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'less-rails-bootstrap'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'sprockets'
  s.add_development_dependency 'therubyracer'
  
  
end
