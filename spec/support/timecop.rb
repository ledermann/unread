def wait
  Timecop.freeze(1.minute.from_now.change(:usec => 0))
end
