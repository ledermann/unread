# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "unread/version"

Gem::Specification.new do |s|
  s.name        = "unread"
  s.version     = Unread::VERSION
  s.licenses    = ['MIT']
  s.authors     = ["Georg Ledermann"]
  s.email       = ["georg@ledermann.dev"]
  s.homepage    = "https://github.com/ledermann/unread"
  s.summary     = %q{Manages read/unread status of ActiveRecord objects}
  s.description = %q{This gem creates a scope for unread objects and adds methods to mark objects as read }
  s.required_ruby_version = '>= 3.0'

  s.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  s.bindir        = "exe"
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'activerecord', '>= 6.1'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'timecop'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'mysql2'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'term-ansicolor'
  s.add_development_dependency 'coveralls_reborn'
  s.add_development_dependency 'appraisal'
end
