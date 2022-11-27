require 'active_record'

require 'unread/base'
require 'unread/readable'
require 'unread/reader'
require 'unread/readable_scopes'
require 'unread/reader_scopes'
require 'unread/garbage_collector'
require 'unread/version'

ActiveSupport.on_load(:active_record) do
  require 'unread/read_mark'

  include Unread
end
