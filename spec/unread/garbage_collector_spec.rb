require 'spec_helper'

describe Unread::GarbageCollector do
  before :each do
    @reader = Reader.create! :name => 'David'
    @other_reader = Reader.create :name => 'Matz'
    @sti_reader = StiReader.create!
    wait
    @email1 = Email.create!
    wait
    @email2 = MultiLevelStiReadable.create!
  end

  describe :run! do
    it "should delete all single read marks" do
      expect(@reader.read_marks.single.count).to eq 0

      @email1.mark_as_read! :for => @reader

      expect(Email.unread_by(@reader)).to eq [@email2]
      expect(@reader.read_marks.single.count).to eq 1

      Unread::GarbageCollector.new(Email).run!

      @reader.reload
      expect(@reader.read_marks.single.count).to eq 0
    end

    it "should reset if all objects are read" do
      @email1.mark_as_read! :for => @reader
      @email2.mark_as_read! :for => @reader

      expect(@reader.read_marks.single.count).to eq 2

      Unread::GarbageCollector.new(Email).run!

      expect(@reader.read_marks.single.count).to eq 0
    end

    it "should not delete read marks from other readables" do
      other_read_mark = @reader.read_marks.create! do |rm|
        rm.readable_type = 'Foo'
        rm.readable_id   = 42
        rm.timestamp     = 5.years.ago
      end

      Unread::GarbageCollector.new(Email).run!

      expect(ReadMark.exists?(other_read_mark.id)).to be_truthy
    end
  end
end
