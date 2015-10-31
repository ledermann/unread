require 'spec_helper'

describe Unread::Reader::Scopes do
  it 'should define reader_scope' do
    expect(Reader.reader_scope).to eq Reader.not_foo.not_bar
    expect(DifferentReader.reader_scope).to eq DifferentReader
    expect(StiReader.reader_scope).to eq StiReader
  end
end
