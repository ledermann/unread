RSpec.describe Unread::GarbageCollector do
  subject(:garbage_collector) { described_class.new(Email) }

  let!(:reader) { Reader.create!(name: 'David') }
  let!(:email) do
    wait
    Email.create!
  end
  let!(:sti_email) do
    wait
    MultiLevelStiReadable.create!
  end

  before do
    Reader.create!(name: 'Matz')
    StiReader.create!
  end

  describe '#run!' do
    it 'deletes all single read marks' do
      email.mark_as_read! for: reader
      expect(Email.unread_by(reader)).to eq [sti_email]
      expect(reader.read_marks.single.count).to eq 1

      garbage_collector.run!

      expect(reader.reload.read_marks.single.count).to eq 0
      expect(Email.unread_by(reader)).to eq [sti_email]
    end

    it 'resets if all objects are read' do
      email.mark_as_read! for: reader
      sti_email.mark_as_read! for: reader
      expect(reader.read_marks.single.count).to eq 2

      garbage_collector.run!

      expect(reader.reload.read_marks.single.count).to eq 0
      expect(Email.unread_by(reader)).to be_empty
    end

    it 'keeps read marks of other readables' do
      other_read_mark = reader.read_marks.create!(readable_type: 'Foo', readable_id: 42, timestamp: 5.years.ago)

      garbage_collector.run!

      expect(ReadMark).to exist(other_read_mark.id)
    end
  end
end
