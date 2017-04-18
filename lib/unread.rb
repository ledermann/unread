require 'active_record'

require 'unread/base'
require 'unread/read_mark'
require 'unread/readable'
require 'unread/reader'
require 'unread/readable_scopes'
require 'unread/reader_scopes'
require 'unread/garbage_collector'
require 'unread/version'

ActiveRecord::Base.send :include, Unread

Unread::MIGRATION_BASE_CLASS = if ActiveRecord::VERSION::MAJOR >= 5
  ActiveRecord::Migration[5.0]
else
  ActiveRecord::Migration
end
