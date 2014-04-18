require 'spec_helper'

describe ReadMark do
  it "should have readable_classes" do
    ReadMark.readable_classes.should eq [ Email ]
  end

  it "should have reader_class" do
    ReadMark.reader_class.should eq Reader
  end
end
