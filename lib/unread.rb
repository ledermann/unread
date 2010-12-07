%w{ models }.each do |dir| 
  path = File.join(File.dirname(__FILE__), 'app', dir)
  $LOAD_PATH << path
  
  if ActiveSupport::Dependencies.respond_to?(:autoload_paths)
    # Rails 2.3.9 or later
    ActiveSupport::Dependencies.autoload_paths << path
    ActiveSupport::Dependencies.autoload_once_paths.delete(path) 
  elsif ActiveSupport::Dependencies.respond_to?(:load_paths)
    # Rails 2.3.8 or less
    ActiveSupport::Dependencies.load_paths << path
    ActiveSupport::Dependencies.load_once_paths.delete(path)
  else
    raise "Unknown error. Perhaps upgrading your Rails version will help."
  end
end

require 'unread/acts_as_readable'