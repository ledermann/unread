RSpec.describe ReadMark do
  it 'knows the reader classes' do
    expect(described_class.reader_classes).to eq [Reader, DifferentReader, StiReader]
  end

  it 'knows the readable classes' do
    expect(described_class.readable_classes).to eq [Document]
  end
end
