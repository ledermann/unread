require 'test/unit'
require 'active_support'
require 'active_support/test_case'
require 'active_record'
require 'timecop'

configs = YAML.load_file(File.dirname(__FILE__) + '/database.yml')
ActiveRecord::Base.configurations = configs

db_name = ENV['DB'] || 'sqlite'
ActiveRecord::Base.establish_connection(db_name)
ActiveRecord::Migration.verbose = false
load(File.dirname(__FILE__) + "/schema.rb")

require 'unread'

class Reader < ActiveRecord::Base
  acts_as_reader
end

class Email < ActiveRecord::Base
  acts_as_readable :on => :updated_at
end

puts "Testing with ActiveRecord #{ActiveRecord::VERSION::STRING}"