require 'spec_helper'

describe Unread::Readable do
  before :each do
    @reader = Reader.create! :name => 'David'
    @other_reader = Reader.create :name => 'Matz'
    wait
    @email1 = Email.create!
    wait
    @email2 = Email.create!
  end

  describe :unread_by do
    it "should return all objects" do
      Email.unread_by(@reader).should eq [@email1, @email2]
      Email.unread_by(@other_reader).should eq [@email1, @email2]
    end

    it "should return unread records" do
      @email1.mark_as_read! :for => @reader

      Email.unread_by(@reader).should eq [@email2]
      Email.unread_by(@reader).count.should eq 1
    end

    it "should not allow invalid parameter" do
      [ 42, nil, 'foo', :foo, {} ].each do |not_a_reader|
        expect {
          Email.unread_by(not_a_reader)
        }.to raise_error(ArgumentError)
      end
    end

    it "should not allow unsaved reader" do
      unsaved_reader = Reader.new

      expect {
        Email.unread_by(unsaved_reader)
      }.to raise_error(ArgumentError)
    end
  end

  describe :with_read_marks_for do
    it "should not allow invalid parameter" do
      [ 42, nil, 'foo', :foo, {} ].each do |not_a_reader|
        expect {
          Email.with_read_marks_for(not_a_reader)
        }.to raise_error(ArgumentError)
      end
    end

    it "should not allow unsaved reader" do
      unsaved_reader = Reader.new

      expect {
        Email.with_read_marks_for(unsaved_reader)
      }.to raise_error(ArgumentError)
    end
  end

  describe :unread? do
    it "should recognize unread object" do
      @email1.unread?(@reader).should be_true
      @email1.unread?(@other_reader).should be_true
    end

    it "should handle updating object" do
      @email1.mark_as_read! :for => @reader
      wait
      @email1.unread?(@reader).should be_false

      @email1.update_attributes! :subject => 'changed'
      @email1.unread?(@reader).should be_true
    end

    it "should raise error for invalid argument" do
      expect {
        @email1.unread?(42)
      }.to raise_error(ArgumentError)
    end

    it "should work with eager-loaded read marks" do
      @email1.mark_as_read! :for => @reader

      expect {
        emails = Email.with_read_marks_for(@reader).to_a

        emails[0].unread?(@reader).should be_false
        emails[1].unread?(@reader).should be_true
      }.to perform_queries(1)
    end
  end

  describe '#mark_as_read!' do
    it "should mark a single object as read" do
      @email1.mark_as_read! :for => @reader

      @email1.unread?(@reader).should be_false
      Email.unread_by(@reader).should eq [@email2]

      @email1.unread?(@other_reader).should be_true
      Email.unread_by(@other_reader).should eq [@email1, @email2]

      @reader.read_marks.single.count.should eq 1
      @reader.read_marks.single.first.readable.should eq @email1
    end

    it "should be idempotent" do
      @email1.mark_as_read! :for => @reader
      @email1.mark_as_read! :for => @reader

      @reader.read_marks.single.count.should eq 1
    end
  end

  describe '.mark_as_read!' do
    it "should mark multi objects as read" do
      @email1.unread?(@reader).should be_true
      @email2.unread?(@reader).should be_true

      Email.mark_as_read! [ @email1, @email2 ], :for => @reader

      @email1.unread?(@reader).should be_false
      @email2.unread?(@reader).should be_false
    end

    it "should mark all objects as read" do
      Email.mark_as_read! :all, :for => @reader

      @reader.read_mark_global(Email).timestamp.should eq Time.current
      @reader.read_marks.single.should eq []
      ReadMark.single.count.should eq 0
      ReadMark.global.count.should eq 2
    end

    it "should mark all objects as read with existing read objects" do
      wait

      Email.mark_as_read! :all, :for => @reader
      @email1.mark_as_read! :for => @reader

      @reader.read_marks.single.should eq []
    end

    it "should not allow invalid arguments" do
      expect {
        Email.mark_as_read! :foo, :for => @reader
      }.to raise_error(ArgumentError)

      expect {
        Email.mark_as_read! :foo, :bar
      }.to raise_error(ArgumentError)
    end
  end

  describe :reset_read_marks_for_all do
    it "should reset read marks" do
      Email.reset_read_marks_for_all

      ReadMark.single.count.should eq 0
      ReadMark.global.count.should eq 2
    end
  end

  describe :cleanup_read_marks! do
    it "should delete all single read marks" do
      @reader.read_marks.single.count.should eq 0

      @email1.mark_as_read! :for => @reader

      Email.unread_by(@reader).should eq [@email2]
      @reader.read_marks.single.count.should eq 1

      Email.cleanup_read_marks!

      @reader.reload
      @reader.read_marks.single.count.should eq 0
    end

    it "should reset if all objects are read" do
      @email1.mark_as_read! :for => @reader
      @email2.mark_as_read! :for => @reader

      @reader.read_marks.single.count.should eq 2

      Email.cleanup_read_marks!

      @reader.read_marks.single.count.should eq 0
    end

    it "should not delete read marks from other readables" do
      other_read_mark = @reader.read_marks.create! :readable_type => 'Foo', :readable_id => 42, :timestamp => 5.years.ago
      Email.cleanup_read_marks!

      ReadMark.exists?(other_read_mark.id).should be_true
    end
  end
end
