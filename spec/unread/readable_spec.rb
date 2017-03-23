require 'spec_helper'

describe Unread::Readable do
  before :each do
    @reader = Reader.create! :name => 'David'
    @other_reader = Reader.create :name => 'Matz'
    @sti_reader = StiReader.create!
    wait
    @email1 = Email.create!
    wait
    @email2 = MultiLevelStiReadable.create!
  end

  describe :unread_by do
    it "should return all objects" do
      expect(Email.unread_by(@reader)).to eq [@email1, @email2]
      expect(Email.unread_by(@other_reader)).to eq [@email1, @email2]
    end

    it "should return unread records" do
      @email1.mark_as_read! :for => @reader

      expect(Email.unread_by(@reader)).to eq [@email2]
      expect(Email.unread_by(@reader).count).to eq 1

      expect(Email.unread_by(@other_reader)).to eq [@email1, @email2]
    end

    it "should return empty array directly after marking all as read" do
      Email.mark_as_read! :all, :for => @reader
      expect(Email.unread_by(@reader)).to eq([])
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

    describe "should work without any read_marks" do
      before do
        ReadMark.delete_all
      end

      it "should return all objects" do
        expect(Email.unread_by(@reader)).to eq [@email1, @email2]
        expect(Email.unread_by(@other_reader)).to eq [@email1, @email2]
      end

      it "should return unread records" do
        @email1.mark_as_read! :for => @reader

        expect(Email.unread_by(@reader)).to eq [@email2]
        expect(Email.unread_by(@reader).count).to eq 1
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
  end

  describe :read_by do
    it "should return an empty array" do
      expect(Email.read_by(@reader)).to be_empty
      expect(Email.read_by(@other_reader)).to be_empty
    end

    it "should return read records" do
      @email1.mark_as_read! :for => @reader

      expect(Email.read_by(@reader)).to eq [@email1]
      expect(Email.read_by(@reader).count).to eq 1
    end

    it "should return all records when all read" do
      Email.mark_as_read! :all, :for => @reader

      expect(Email.read_by(@reader)).to eq [@email1, @email2]
    end

    it "should not allow invalid parameter" do
      [ 42, nil, 'foo', :foo, {} ].each do |not_a_reader|
        expect {
          Email.read_by(not_a_reader)
        }.to raise_error(ArgumentError)
      end
    end

    it "should not allow unsaved reader" do
      unsaved_reader = Reader.new

      expect {
        Email.read_by(unsaved_reader)
      }.to raise_error(ArgumentError)
    end

    describe "should work without any read_marks" do
      before do
        ReadMark.delete_all
      end

      it "should return an empty array" do
        expect(Email.read_by(@reader)).to be_empty
        expect(Email.read_by(@other_reader)).to be_empty
      end

      it "should return read records" do
        @email1.mark_as_read! :for => @reader

        expect(Email.read_by(@reader)).to eq [@email1]
        expect(Email.read_by(@reader).count).to eq 1
      end

      it "should return all records when all read" do
        Email.mark_as_read! :all, :for => @reader

        expect(Email.read_by(@reader)).to eq [@email1, @email2]
      end

      it "should not allow invalid parameter" do
        [ 42, nil, 'foo', :foo, {} ].each do |not_a_reader|
          expect {
            Email.read_by(not_a_reader)
          }.to raise_error(ArgumentError)
        end
      end

      it "should not allow unsaved reader" do
        unsaved_reader = Reader.new

        expect {
          Email.read_by(unsaved_reader)
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe :with_read_marks_for do
    it "should return readables" do
      expect(Email.with_read_marks_for(@reader).to_a).to eq([@email1, @email2])
    end

    it "should be countable" do
      expect(Email.with_read_marks_for(@reader).count(:uid)).to eq(2)
    end

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
      expect(@email1.unread?(@reader)).to be_truthy
      expect(@email1.unread?(@other_reader)).to be_truthy
    end

    it "should handle updating object" do
      @email1.mark_as_read! :for => @reader
      wait
      expect(@email1.unread?(@reader)).to be_falsey

      @email1.update_attributes! :subject => 'changed'
      expect(@email1.unread?(@reader)).to be_truthy
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

        expect(emails[0].unread?(@reader)).to be_falsey
        expect(emails[1].unread?(@reader)).to be_truthy
      }.to perform_queries(1)
    end

    it "should work without any read_marks" do
      ReadMark.delete_all

      emails = Email.with_read_marks_for(@reader).to_a
      expect(emails[0].unread?(@reader)).to be_truthy
      expect(emails[1].unread?(@reader)).to be_truthy
    end

    it "should work with eager-loaded read marks for the correct reader" do
      @email1.mark_as_read! :for => @reader

      emails = Email.with_read_marks_for(@reader).to_a
      expect(emails[0].unread?(@reader)).to be_falsey
      expect(emails[0].unread?(@other_reader)).to be_truthy
    end
  end

  describe '#mark_as_read!' do
    it "should mark a single object as read" do
      @email1.mark_as_read! :for => @reader

      expect(@email1.unread?(@reader)).to be_falsey
      expect(Email.unread_by(@reader)).to eq [@email2]

      expect(@email1.unread?(@other_reader)).to be_truthy
      expect(Email.unread_by(@other_reader)).to eq [@email1, @email2]

      expect(@reader.read_marks.single.count).to eq 1
      expect(@reader.read_marks.single.first.readable).to eq @email1
    end

    it "should be idempotent" do
      @email1.mark_as_read! :for => @reader
      @email1.mark_as_read! :for => @reader

      expect(@reader.read_marks.single.count).to eq 1
    end
  end

  describe '.mark_as_read!' do
    it "should mark multi objects as read" do
      expect(@email1.unread?(@reader)).to be_truthy
      expect(@email2.unread?(@reader)).to be_truthy

      Email.mark_as_read! [ @email1, @email2 ], :for => @reader

      expect(@email1.unread?(@reader)).to be_falsey
      expect(@email2.unread?(@reader)).to be_falsey
    end

    it "should mark the rest as read when the first record is not unique" do
      Email.mark_as_read! [ @email1 ], for: @reader

      allow(@email1).to receive_message_chain("read_marks.build").and_return(@email1.read_marks.build)
      allow(@email1).to receive_message_chain("read_marks.where").and_return([])

      expect do
        Email.mark_as_read! [ @email1, @email2 ], for: @reader
      end.to change(ReadMark, :count).by(1)

      expect(@email1.unread?(@reader)).to be_falsey
      expect(@email2.unread?(@reader)).to be_falsey
    end

    it "should perform less queries if the objects are already read" do
      Email.mark_as_read! :all, :for => @reader

      expect {
        Email.mark_as_read! [ @email1, @email2 ], :for => @reader
      }.to perform_queries(1)
    end

    it "should mark all objects as read" do
      Email.mark_as_read! :all, :for => @reader

      expect(@reader.read_mark_global(Email).timestamp).to eq Time.current
      expect(@reader.read_marks.single).to eq []
      expect(ReadMark.single.count).to eq 0
      expect(ReadMark.global.count).to eq 3
    end

    it "should mark all objects as read with existing read objects" do
      wait

      Email.mark_as_read! :all, :for => @reader
      @email1.mark_as_read! :for => @reader

      expect(@reader.read_marks.single).to eq []
    end

    it "should reset memoized global read mark" do
      rm_global = @reader.read_mark_global(Email)

      Email.mark_as_read! :all, :for => @reader
      expect(@reader.read_mark_global(Email)).not_to eq(rm_global)
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

  describe :cleanup_read_marks! do
    it "should run garbage collector" do
      expect(Unread::GarbageCollector).to receive(:new).with(Email).and_return(double :run! => true)
      Email.cleanup_read_marks!
    end
  end
end
