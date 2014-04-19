require 'spec_helper'

describe Unread::Base do
  before :each do
    @email = Email.create!
    wait
    @reader = Reader.create! :name => 'John'
  end

  describe :acts_as_reader do
    it "should create global read mark" do
      @reader.read_marks.count.should eq 1
      @reader.read_marks.global.count.should eq 1
    end

    it "should define association for ReadMark" do
      @reader.read_marks.first.user.should == @reader
    end

    it "should reset read_marks for created reader" do
      Email.unread_by(@reader).should be_empty
    end
  end

  describe :acts_as_readable do
    it "should define association" do
      @email.read_marks.count.should eq 0
    end

    it "should add class to ReadMark.readable_classes" do
      ReadMark.readable_classes.should eq [ Email ]
    end

    it "should use default options" do
      Email.readable_options.should == { :on => :updated_at }
    end
  end
end
