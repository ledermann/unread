# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "unread/version"
require 'active_record/version'

Gem::Specification.new do |s|
  s.name        = "unread"
  s.version     = Unread::VERSION
  s.authors     = ["Georg Ledermann"]
  s.email       = ["mail@georg-ledermann.de"]
  s.homepage    = ""
  s.summary     = %q{Manages read/unread status of ActiveRecord objects}
  s.description = %q{This gem creates a scope for unread objects and adds methods to mark objects as read }

  s.rubyforge_project = "unread"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency 'activerecord', '>= 2.3'
  
  s.add_development_dependency 'rake'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'sqlite3'
  
  if ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR >= 1
    s.add_development_dependency 'mysql2', '>= 0.3.6'
  else
    s.add_development_dependency 'mysql2', '~> 0.2.11'
  end
end