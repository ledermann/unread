module Unread
  module Generators
    module MigrationHelper
      def mysql?
        defined?(ActiveRecord::ConnectionAdapters::Mysql2Adapter) \
          && ActiveRecord::Base.connection.instance_of?(ActiveRecord::ConnectionAdapters::Mysql2Adapter)
      end

      def postgresql_9_5?
        defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) \
          && ActiveRecord::Base.connection.instance_of?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) \
          && ActiveRecord::Base.connection.send(:postgresql_version) >= 90500
      end
    end
  end
end
