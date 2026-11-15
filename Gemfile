source 'https://rubygems.org'

gemspec

# Select the Rails version with RAILS_VERSION, for example "8.1" or "edge"
rails_version = ENV.fetch('RAILS_VERSION', '8.1')
if rails_version == 'edge'
  gem 'activerecord', github: 'rails/rails', branch: 'main'
  gem 'railties', github: 'rails/rails', branch: 'main'
else
  gem 'activerecord', "~> #{rails_version}.0"
  gem 'railties', "~> #{rails_version}.0"
end

gem 'mysql2'
gem 'pg'
gem 'sqlite3'
gem 'trilogy'

gem 'irb'
gem 'rake'
gem 'rspec'
gem 'simplecov', require: false

gem 'rubocop', require: false
gem 'rubocop-performance', require: false
gem 'rubocop-rake', require: false
gem 'rubocop-rspec', require: false
