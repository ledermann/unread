RSpec::Matchers.define :perform_queries do |expected|
  supports_block_expectations

  match do |block|
    query_count(&block) == expected
  end

  failure_message do |actual|
    "Expected to run #{expected} queries, got #{@counter.query_count}"
  end

  def query_count(&block)
    @counter = ActiveRecord::QueryCounter.new
    ActiveSupport::Notifications.subscribed(@counter.to_proc, 'sql.active_record', &block)
    @counter.query_count
  end
end
