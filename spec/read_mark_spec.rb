require 'spec_helper'

describe ReadMark do
  it "should have reader_class" do
    ReadMark.reader_class.should eq Reader
  end
end
