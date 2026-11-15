RSpec.describe Unread::Base do
  let!(:email) { Email.create! }
  let!(:reader) do
    wait
    Reader.create!(name: 'John')
  end

  describe '.acts_as_reader' do
    it 'creates a global read mark' do
      expect(reader.read_marks.count).to eq 1
      expect(reader.read_marks.global.count).to eq 1
    end

    it 'defines the association for ReadMark' do
      expect(reader.read_marks.first.reader).to eq reader
    end

    it 'starts a new reader with zero unread records' do
      expect(Email.unread_by(reader)).to be_empty
    end

    it 'memoizes read_mark_global' do
      expect do
        reader.read_mark_global(Email)
        reader.read_mark_global(Email)
      end.to perform_queries(1)
    end

    it 'adds only the public API to the reader' do
      expect(Reader).not_to respond_to(:join_read_marks)
      expect(reader).not_to respond_to(:forget_memoized_read_mark_global, :setup_new_reader)
    end

    it 'is idempotent' do
      expect { 3.times { Reader.acts_as_reader } }.not_to(change(ReadMark, :reader_classes))
    end
  end

  describe '.acts_as_readable' do
    it 'defines the association' do
      expect(email.read_marks.count).to eq 0
    end

    it 'adds the class to ReadMark.readable_classes' do
      expect(ReadMark.readable_classes).to eq [Document]
    end

    it 'uses default options' do
      expect(Email.readable_options).to eq(on: :updated_at)
    end

    it 'adds only the public API to the readable' do
      expect(Email).not_to respond_to(
        :join_read_marks, :mark_collection_as_read, :mark_collection_item_as_read,
        :reset_read_marks_for_user, :assert_reader, :readable_parent,
      )
    end

    it 'is idempotent' do
      expect { 3.times { Document.acts_as_readable } }.not_to(change(ReadMark, :readable_classes))
    end
  end
end
