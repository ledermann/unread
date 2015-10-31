require 'spec_helper'

describe ReadMark do
  it "should have reader_class" do
    expect(ReadMark.reader_classes).to eq [Reader, DifferentReader, StiReader]
  end

  it "should have reader_scope" do
    expect(Reader.reader_scope).to eq Reader.not_foo.not_bar
    expect(DifferentReader.reader_scope).to eq DifferentReader
    expect(StiReader.reader_scope).to eq StiReader
  end

  it "should have readable_classes" do
    expect(ReadMark.readable_classes).to eq [Document]
  end
end
