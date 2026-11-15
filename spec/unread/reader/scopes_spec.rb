RSpec.describe Unread::Reader::Scopes do
  describe '.reader_scope' do
    it 'can be overridden' do
      expect(Reader.reader_scope).to eq Reader.not_foo.not_bar
    end

    it 'defaults to all records' do
      expect(DifferentReader.reader_scope).to eq DifferentReader
      expect(StiReader.reader_scope).to eq StiReader
    end
  end
end
