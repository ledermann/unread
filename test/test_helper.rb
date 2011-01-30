require 'rubygems'

gem 'activerecord'
gem 'mocha'

require 'test/unit'
require 'active_record'
require 'active_support'
require 'active_support/test_case'

require File.dirname(__FILE__) + '/../init.rb'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.establish_connection(config['sqlite3mem'])
ActiveRecord::Migration.verbose = false
load(File.dirname(__FILE__) + "/schema.rb")

class User < ActiveRecord::Base
  acts_as_reader
end

class Email < ActiveRecord::Base
  acts_as_readable :on => :updated_at
end