source 'https://rubygems.org'

gem 'rails', '3.2.8'

gem 'bson'
gem 'bson_ext'
gem 'cfoundry'
gem 'configatron'
gem 'deface'
gem 'em-http-request'
gem 'haml-rails'
gem 'mongoid'
gem 'mongoid_rails_migrations', '~> 1.0.0'
gem 'nats', '0.4.24', :require => 'nats/client'
gem 'yajl-ruby'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem "cf-twitter-bootstrap-rails", :require => 'twitter-bootstrap-rails'
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

gem 'cf-runtime'
gem 'thin'

# To use debugger
# gem 'debugger'

Dir.glob File.expand_path("../plugins/*/Gemfile", __FILE__) do |file|
  puts "Loading #{file} ..." if $DEBUG # `ruby -d` or `bundle -v`
  instance_eval File.read(file)
end
