require 'spec_helper'

describe ReadMark do
  it "should have reader_class" do
    expect(ReadMark.reader_classes).to eq [Reader, DifferentReader]
  end

  it "should have reader_scope" do
    expect(ReadMark.reader_scope).to eq Reader.not_foo.not_bar
  end

  it "should have reader_scope with klass" do
    expect(ReadMark.reader_scope(Reader)).to eq Reader.not_foo.not_bar
  end

  it "should have readable_classes" do
    expect(ReadMark.readable_classes).to eq [Document]
  end
end
