require 'unread/base'
require 'unread/read_mark'
require 'unread/readable'
require 'unread/reader'
require 'unread/scopes'
require 'unread/version'

ActiveRecord::Base.send :include, Unread