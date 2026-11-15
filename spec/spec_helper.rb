require 'simplecov'
SimpleCov.start do
  enable_coverage :branch
  cover 'lib/**/*.rb'
  # Bundler loads this file via the gemspec before SimpleCov starts
  skip 'lib/unread/version.rb'
  minimum_coverage line: 100, branch: 100
end

require 'erb'
require 'unread'
require 'active_support/testing/time_helpers'

require 'app/models'

Dir[File.join(__dir__, 'support/**/*.rb')].each { |file| require file }

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
  config.include TimeHelpers

  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before do
    Database.clear
  end

  config.after do
    travel_back
  end

  config.after :suite do
    Database.teardown
  end
end

Database.setup
