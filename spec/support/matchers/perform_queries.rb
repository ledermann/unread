RSpec::Matchers.define :perform_queries do |expected|
  supports_block_expectations

  match do |block|
    @count = 0
    counter = lambda do |*, payload|
      @count += 1 unless payload[:cached] || %w[CACHE SCHEMA TRANSACTION].include?(payload[:name])
    end

    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &block)
    @count == expected
  end

  failure_message do
    "expected to perform #{expected} queries, but performed #{@count}"
  end
end
