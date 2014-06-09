require 'spec_helper'

describe Unread::Base do
  before :each do
    @email = Email.create!
    wait
    @reader = Reader.create! :name => 'John'
  end

  describe :acts_as_reader do
    it "should create global read mark" do
      expect(@reader.read_marks.count).to eq 1
      expect(@reader.read_marks.global.count).to eq 1
    end

    it "should define association for ReadMark" do
      expect(@reader.read_marks.first.user).to eq(@reader)
    end

    it "should reset read_marks for created reader" do
      expect(Email.unread_by(@reader)).to be_empty
    end
  end

  describe :acts_as_readable do
    it "should define association" do
      expect(@email.read_marks.count).to eq 0
    end

    it "should add class to ReadMark.readable_classes" do
      expect(ReadMark.readable_classes).to eq [ Email ]
    end

    it "should use default options" do
      expect(Email.readable_options).to eq({ :on => :updated_at })
    end
  end
end
