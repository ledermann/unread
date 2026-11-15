# The including group must define `action`, a lambda taking the argument to check

RSpec.shared_examples 'a method requiring a reader' do
  it 'raises for invalid arguments' do
    [42, nil, 'foo', :foo, {}].each do |not_a_reader|
      expect { action.call(not_a_reader) }.to raise_error(ArgumentError)
    end
  end

  it 'raises for an unsaved reader' do
    expect { action.call(Reader.new) }.to raise_error(ArgumentError)
  end
end

RSpec.shared_examples 'a method requiring a readable' do
  it 'raises for invalid arguments' do
    [42, nil, 'foo', :foo, {}].each do |not_a_readable|
      expect { action.call(not_a_readable) }.to raise_error(ArgumentError)
    end
  end

  it 'raises for an unsaved readable' do
    expect { action.call(Email.new) }.to raise_error(ArgumentError)
  end
end
