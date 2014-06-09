require 'spec_helper'

describe ReadMark do
  it "should have reader_class" do
    expect(ReadMark.reader_class).to eq Reader
  end
end
