require 'unread/version'
require 'app/models/read_mark'
require 'unread/scopes'
require 'unread/acts_as_readable'

ActiveRecord::Base.send :include, Unread