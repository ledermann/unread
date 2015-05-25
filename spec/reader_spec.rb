require 'spec_helper'

describe Unread::Reader do
  before :each do
    @reader = Reader.create! :name => 'David'
    @other_reader = Reader.create :name => 'Matz'
    wait
    @email1 = Email.create!
    wait
    @email2 = Email.create!
  end

  describe :have_not_read do
    it "should return all readers that have not read a given object" do
      expect(Reader.have_not_read(@email1)).to eq [@reader, @other_reader]
      expect(Reader.have_not_read(@email2)).to eq [@reader, @other_reader]
    end

    it "should return *only* the readers that have not read a given object" do
      @email1.mark_as_read! :for => @reader

      expect(Reader.have_not_read(@email1)).to eq [@other_reader]
      expect(Reader.have_not_read(@email1).count).to eq 1

      expect(Reader.have_not_read(@email2)).to eq [@reader, @other_reader]
    end

    it "should not allow invalid parameter" do
      [ 42, nil, 'foo', :foo, {} ].each do |not_a_readable|
        expect {
          Reader.have_not_read(not_a_readable)
        }.to raise_error(ArgumentError)
      end
    end

    it "should not allow unsaved readable" do
      unsaved_readable = Email.new

      expect {
        Reader.have_not_read(unsaved_readable)
      }.to raise_error(ArgumentError)
    end
  end

  describe :have_read do
    it "should return an empty array" do
      expect(Reader.have_read(@email1)).to be_empty
      expect(Reader.have_read(@email2)).to be_empty
    end

    it "should return *only* the readers that have read the given object" do
      @email1.mark_as_read! :for => @reader

      expect(Reader.have_read(@email1)).to eq [@reader]
      expect(Reader.have_read(@email1).count).to eq 1

      expect(Reader.have_read(@email2)).to be_empty
    end

    it "should return the reader for all the object when all read" do
      Email.mark_as_read! :all, :for => @reader

      expect(Reader.have_read(@email1)).to eq [@reader]
      expect(Reader.have_read(@email1).count).to eq 1

      expect(Reader.have_read(@email2)).to eq [@reader]
      expect(Reader.have_read(@email2).count).to eq 1
    end

    it "should not allow invalid parameter" do
      [ 42, nil, 'foo', :foo, {} ].each do |not_a_readable|
        expect {
          Reader.have_read(not_a_readable)
        }.to raise_error(ArgumentError)
      end
    end

    it "should not allow unsaved readable" do
      unsaved_readable = Email.new

      expect {
        Reader.have_read(unsaved_readable)
      }.to raise_error(ArgumentError)
    end
  end

  describe :with_read_marks_for do
    it "should return readers" do
      expect(Reader.with_read_marks_for(@email1).to_a).to eq([@reader, @other_reader])
    end

    it "should have elements that respond to :read_mark_id" do
      all_respond_to_read_mark_id = Reader.with_read_marks_for(@email1).to_a.all? do |reader|
        reader.respond_to?(:read_mark_id)
      end

      expect(all_respond_to_read_mark_id).to be_truthy
    end

    it "should be countable" do
      expect(Reader.with_read_marks_for(@email1).count(:number)).to eq(2)
    end

    it "should not allow invalid parameter" do
      [ 42, nil, 'foo', :foo, {} ].each do |not_a_readable|
        expect {
          Reader.with_read_marks_for(not_a_readable)
        }.to raise_error(ArgumentError)
      end
    end

    it "should not allow unsaved readable" do
      unsaved_readable = Email.new

      expect {
        Reader.with_read_marks_for(unsaved_readable)
      }.to raise_error(ArgumentError)
    end
  end

  describe :have_read? do
    it "should recognize read objects" do
      expect(@reader.have_read?(@email1)).to be_falsey
      expect(@reader.have_read?(@email2)).to be_falsey
    end

    it "should handle updating object" do
      @email1.mark_as_read! :for => @reader
      wait
      expect(@reader.have_read?(@email1)).to be_truthy

      @email1.update_attributes! :subject => 'changed'
      expect(@reader.have_read?(@email1)).to be_falsey
    end

    it "should raise error for invalid argument" do
      expect {
        @reader.have_read?(42)
      }.to raise_error(ArgumentError)
    end

    it "should work with eager-loaded read marks" do
      @email1.mark_as_read! :for => @reader

      expect {
        readers = Reader.with_read_marks_for(@email1).to_a

        expect(readers[0].have_read?(@email1)).to be_truthy
        expect(readers[1].have_read?(@email1)).to be_falsey
      }.to perform_queries(1)
    end
  end
end