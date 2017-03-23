# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "unread/version"

Gem::Specification.new do |s|
  s.name        = "unread"
  s.version     = Unread::VERSION
  s.licenses    = ['MIT']
  s.authors     = ["Georg Ledermann"]
  s.email       = ["mail@georg-ledermann.de"]
  s.homepage    = "https://github.com/ledermann/unread"
  s.summary     = %q{Manages read/unread status of ActiveRecord objects}
  s.description = %q{This gem creates a scope for unread objects and adds methods to mark objects as read }
  s.required_ruby_version = '>= 2.0.0'

  s.rubyforge_project = "unread"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'activerecord', '>= 3'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'timecop'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'mysql2'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'term-ansicolor'
  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'appraisal'
end
