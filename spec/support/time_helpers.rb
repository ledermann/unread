module TimeHelpers
  # Freeze the time one minute later, without microseconds
  def wait
    travel 1.minute
  end
end
