require_relative 'lib/unread/version'

Gem::Specification.new do |spec|
  spec.name        = 'unread'
  spec.version     = Unread::VERSION
  spec.license     = 'MIT'
  spec.authors     = ['Georg Ledermann']
  spec.email       = ['georg@ledermann.dev']
  spec.homepage    = 'https://github.com/ledermann/unread'
  spec.summary     = 'Manages read/unread status of ActiveRecord objects'
  spec.description = 'This gem creates a scope for unread objects and adds methods to mark objects as read'
  spec.required_ruby_version = '>= 3.3'

  spec.metadata = {
    'source_code_uri' => spec.homepage,
    'changelog_uri' => "#{spec.homepage}/releases",
    'bug_tracker_uri' => "#{spec.homepage}/issues",
    'rubygems_mfa_required' => 'true',
  }

  spec.files = Dir['lib/**/*', 'MIT-LICENSE', 'README.md', 'UPGRADE.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 8.1'
end
