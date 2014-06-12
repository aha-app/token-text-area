require 'sprockets'
require 'coffee_script'
require 'less-rails-bootstrap'

map '/assets' do
  environment = Sprockets::Environment.new do |env|
  env.logger = Logger.new(STDOUT)
  end
  environment.append_path 'vendor/assets/javascripts'
  environment.append_path 'vendor/assets/stylesheets'
  run environment
end

map '/' do
  use Rack::Static, :urls => ["/examples", "/vendor"]
  run lambda {|*|}
end
