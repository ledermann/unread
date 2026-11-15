RSpec.describe Unread::Reader do
  let!(:reader) { Reader.create!(name: 'David') }
  let!(:other_reader) { Reader.create!(name: 'Matz') }
  let!(:different_reader) { DifferentReader.create!(name: 'Behrooz', number: reader.number) }
  let!(:email) do
    wait
    Email.create!
  end
  let!(:sti_email) do
    wait
    MultiLevelStiReadable.create!
  end

  describe '.have_not_read' do
    it 'returns all readers that have not read a given object' do
      expect(Reader.have_not_read(email)).to eq [reader, other_reader]
      expect(Reader.have_not_read(sti_email)).to eq [reader, other_reader]
    end

    it 'returns *only* the readers that have not read a given object' do
      email.mark_as_read! for: reader

      expect(Reader.have_not_read(email)).to eq [other_reader]
      expect(Reader.have_not_read(email).count).to eq 1
      expect(Reader.have_not_read(sti_email)).to eq [reader, other_reader]
    end

    it 'takes the type of reader into account', :aggregate_failures do
      # reader and different_reader share the same id, but they are of
      # different types, so email must only be marked as read for reader
      email.mark_as_read! for: reader

      expect(Reader.have_not_read(email)).to eq [other_reader]
      expect(DifferentReader.have_not_read(email)).to eq [different_reader]

      email.mark_as_read! for: different_reader

      expect(DifferentReader.have_not_read(email)).to be_empty
      expect(Reader.have_not_read(sti_email)).to eq [reader, other_reader]
    end

    it_behaves_like 'a method requiring a readable' do
      let(:action) { ->(readable) { Reader.have_not_read(readable) } }
    end
  end

  describe '.have_read' do
    it 'returns nothing if nothing is read' do
      expect(Reader.have_read(email)).to be_empty
      expect(Reader.have_read(sti_email)).to be_empty
    end

    it 'returns *only* the readers that have read the given object' do
      email.mark_as_read! for: reader

      expect(Reader.have_read(email)).to eq [reader]
      expect(Reader.have_read(email).count).to eq 1
      expect(Reader.have_read(sti_email)).to be_empty
    end

    it 'returns the reader for all objects when all are read' do
      Email.mark_as_read! :all, for: reader

      expect(Reader.have_read(email)).to eq [reader]
      expect(Reader.have_read(sti_email)).to eq [reader]
    end

    it_behaves_like 'a method requiring a readable' do
      let(:action) { ->(readable) { Reader.have_read(readable) } }
    end
  end

  describe '.with_read_marks_for' do
    it 'returns readers' do
      expect(Reader.with_read_marks_for(email).to_a).to eq [reader, other_reader]
    end

    it 'returns elements that respond to :read_mark_id' do
      expect(Reader.with_read_marks_for(email).to_a).to all(respond_to(:read_mark_id))
    end

    it 'is countable' do
      expect(Reader.with_read_marks_for(email).count(:number)).to eq 2
    end

    it_behaves_like 'a method requiring a readable' do
      let(:action) { ->(readable) { Reader.with_read_marks_for(readable) } }
    end
  end

  describe '#have_read?' do
    it 'recognizes unread objects' do
      expect(reader.have_read?(email)).to be false
      expect(reader.have_read?(sti_email)).to be false
    end

    it 'handles an updated object' do
      email.mark_as_read! for: reader
      wait
      expect(reader.have_read?(email)).to be true

      email.update!(subject: 'changed')
      expect(reader.have_read?(email)).to be false
    end

    it 'raises for an invalid argument' do
      expect { reader.have_read?(42) }.to raise_error(ArgumentError)
    end

    it 'works with eager-loaded read marks' do
      email.mark_as_read! for: reader

      expect do
        readers = Reader.with_read_marks_for(email).to_a

        expect(readers[0].have_read?(email)).to be true
        expect(readers[1].have_read?(email)).to be false
      end.to perform_queries(1)
    end

    it 'works with eager-loaded read marks for the correct readable' do
      email.mark_as_read! for: reader

      readers = Reader.with_read_marks_for(email).to_a
      expect(readers[0].have_read?(email)).to be true
      expect(readers[0].have_read?(sti_email)).to be false
    end
  end
end
