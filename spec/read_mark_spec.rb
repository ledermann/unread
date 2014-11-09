require 'spec_helper'

describe ReadMark do
  it "should have reader_class" do
    expect(ReadMark.reader_class).to eq Reader
  end

  it "should have reader_scope" do
    expect(ReadMark.reader_scope).to eq Reader.not_foo.not_bar
  end
end
