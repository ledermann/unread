require 'active_record'

require 'unread/base'
require 'unread/readable'
require 'unread/reader'
require 'unread/readable_scopes'
require 'unread/reader_scopes'
require 'unread/garbage_collector'
require 'unread/version'

Unread::MIGRATION_BASE_CLASS = if ActiveRecord::VERSION::MAJOR >= 5
  ActiveRecord::Migration[5.0]
else
  ActiveRecord::Migration
end

ActiveSupport.on_load(:active_record) do
  require 'unread/read_mark'

  include Unread
end
