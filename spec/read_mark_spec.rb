require 'spec_helper'

describe ReadMark do
  it "should have reader_class" do
    expect(ReadMark.reader_class).to eq Reader
  end

  it "should have readable_classes" do
    expect(ReadMark.readable_classes).to eq [Email]
  end
end
