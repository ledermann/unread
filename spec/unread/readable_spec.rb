RSpec.describe Unread::Readable do
  let!(:reader) { Reader.create!(name: 'David') }
  let!(:other_reader) { Reader.create!(name: 'Matz') }
  let!(:sti_reader) { StiReader.create! }
  let!(:email) do
    wait
    Email.create!
  end
  let!(:sti_email) do
    wait
    MultiLevelStiReadable.create!
  end

  describe '.unread_by' do
    shared_examples 'unread_by' do
      it 'returns all objects' do
        expect(Email.unread_by(reader)).to contain_exactly(email, sti_email)
        expect(Email.unread_by(other_reader)).to contain_exactly(email, sti_email)
      end

      it 'returns unread records' do
        email.mark_as_read! for: reader

        expect(Email.unread_by(reader)).to eq [sti_email]
        expect(Email.unread_by(reader).count).to eq 1
        expect(Email.unread_by(other_reader)).to contain_exactly(email, sti_email)
      end

      it 'returns nothing after marking all as read' do
        Email.mark_as_read! :all, for: reader

        expect(Email.unread_by(reader)).to be_empty
      end

      it_behaves_like 'a method requiring a reader' do
        let(:action) { ->(reader) { Email.unread_by(reader) } }
      end
    end

    it_behaves_like 'unread_by'

    context 'without any read marks' do
      before { ReadMark.delete_all }

      it_behaves_like 'unread_by'
    end
  end

  describe '.read_by' do
    shared_examples 'read_by' do
      it 'returns nothing if nothing is read' do
        expect(Email.read_by(reader)).to be_empty
        expect(Email.read_by(other_reader)).to be_empty
      end

      it 'returns read records' do
        email.mark_as_read! for: reader

        expect(Email.read_by(reader)).to eq [email]
        expect(Email.read_by(reader).count).to eq 1
      end

      it 'returns all records when all are read' do
        Email.mark_as_read! :all, for: reader

        expect(Email.read_by(reader)).to contain_exactly(email, sti_email)
      end

      it_behaves_like 'a method requiring a reader' do
        let(:action) { ->(reader) { Email.read_by(reader) } }
      end
    end

    it_behaves_like 'read_by'

    context 'without any read marks' do
      before { ReadMark.delete_all }

      it_behaves_like 'read_by'
    end
  end

  describe '.with_read_marks_for' do
    it 'returns readables' do
      expect(Email.with_read_marks_for(reader).order(:uid).to_a).to contain_exactly(email, sti_email)
    end

    it 'is countable' do
      expect(Email.with_read_marks_for(reader).count(:uid)).to eq 2
    end

    it_behaves_like 'a method requiring a reader' do
      let(:action) { ->(reader) { Email.with_read_marks_for(reader) } }
    end
  end

  describe '#unread?' do
    it 'recognizes an unread object' do
      expect(email.unread?(reader)).to be true
      expect(email.unread?(other_reader)).to be true
    end

    it 'handles an updated object' do
      email.mark_as_read! for: reader
      wait
      expect(email.unread?(reader)).to be false

      email.update!(subject: 'changed')
      expect(email.unread?(reader)).to be true
    end

    it 'raises for an invalid argument' do
      expect { email.unread?(42) }.to raise_error(ArgumentError)
    end

    it 'works with eager-loaded read marks' do
      email.mark_as_read! for: reader

      expect do
        emails = Email.with_read_marks_for(reader).order(:uid).to_a

        expect(emails[0].unread?(reader)).to be false
        expect(emails[1].unread?(reader)).to be true
      end.to perform_queries(1)
    end

    it 'works without any read marks' do
      ReadMark.delete_all

      emails = Email.with_read_marks_for(reader).order(:uid).to_a
      expect(emails[0].unread?(reader)).to be true
      expect(emails[1].unread?(reader)).to be true
    end

    it 'works with eager-loaded read marks for the correct reader' do
      email.mark_as_read! for: reader

      emails = Email.with_read_marks_for(reader).order(:uid).to_a
      expect(emails[0].unread?(reader)).to be false
      expect(emails[0].unread?(other_reader)).to be true
    end
  end

  describe '#read?' do
    it 'is the opposite of unread?' do
      email.mark_as_read! for: reader

      expect(email.read?(reader)).to be true
      expect(sti_email.read?(reader)).to be false
    end
  end

  describe '#mark_as_read!' do
    it 'marks a single object as read', :aggregate_failures do
      email.mark_as_read! for: reader

      expect(email.unread?(reader)).to be false
      expect(Email.unread_by(reader)).to eq [sti_email]

      expect(email.unread?(other_reader)).to be true
      expect(Email.unread_by(other_reader)).to contain_exactly(email, sti_email)

      expect(reader.read_marks.single.count).to eq 1
      expect(reader.read_marks.single.first.readable).to eq email
    end

    it 'is idempotent' do
      email.mark_as_read! for: reader
      email.mark_as_read! for: reader

      expect(reader.read_marks.single.count).to eq 1
    end

    context 'when the reader class has a default_scope that excludes the reader' do
      let(:reader_class) do
        stub_const('CustomReader', Class.new(ActiveRecord::Base) do
          self.primary_key = 'number'
          self.table_name = 'readers'

          acts_as_reader

          default_scope { where.not(name: 'foo') }
        end,)
      end
      let!(:custom_reader) { reader_class.create!(name: 'foo') }
      let!(:document) do
        wait
        Document.create!
      end

      after { ReadMark.reader_classes.delete(reader_class) }

      it 'does not raise an error' do
        expect { document.mark_as_read!(for: custom_reader) }.not_to raise_error
      end
    end
  end

  describe '.mark_as_read!' do
    it 'marks multiple objects as read' do
      Email.mark_as_read! [email, sti_email], for: reader

      expect(email.unread?(reader)).to be false
      expect(sti_email.unread?(reader)).to be false
    end

    it 'marks the rest as read when the first record is not unique' do
      Email.mark_as_read! [email], for: reader

      allow(email).to receive_message_chain('read_marks.find_or_initialize_by') # rubocop:disable RSpec/MessageChain
        .and_return(email.read_marks.build(reader:))

      expect do
        Email.mark_as_read! [email, sti_email], for: reader
      end.to change(ReadMark, :count).by(1)

      expect(email.unread?(reader)).to be false
      expect(sti_email.unread?(reader)).to be false
    end

    it 'performs fewer queries if the objects are already read' do
      Email.mark_as_read! :all, for: reader

      expect do
        Email.mark_as_read! [email, sti_email], for: reader
      end.to perform_queries(1)
    end

    it 'marks a relation as read' do
      Email.mark_as_read! Email.all, for: reader

      expect(email.unread?(reader)).to be false
      expect(sti_email.unread?(reader)).to be false
    end

    it 'marks only the records of a relation with :all' do
      Email.where(type: 'MultiLevelStiReadable').mark_as_read! :all, for: reader

      expect(Email.unread_by(reader)).to eq [email]
      expect(reader.read_mark_global(Email).timestamp).to be < email.updated_at
    end

    it 'marks all objects as read' do
      Email.mark_as_read! :all, for: reader

      expect(reader.read_mark_global(Email).timestamp).to eq Time.current
      expect(reader.read_marks.single).to be_empty
      expect(ReadMark.single.count).to eq 0
      expect(ReadMark.global.count).to eq 3
    end

    it 'marks all objects as read with existing read objects' do
      wait

      Email.mark_as_read! :all, for: reader
      email.mark_as_read! for: reader

      expect(reader.read_marks.single).to be_empty
    end

    it 'resets the memoized global read mark' do
      read_mark_global = reader.read_mark_global(Email)

      Email.mark_as_read! :all, for: reader
      expect(reader.read_mark_global(Email)).not_to eq read_mark_global
    end

    it 'marks objects as read without a global read mark' do
      ReadMark.delete_all

      Email.mark_as_read! [email], for: reader

      expect(Email.unread_by(reader)).to eq [sti_email]
    end

    it 'raises for invalid arguments' do
      expect { Email.mark_as_read! :foo, for: reader }.to raise_error(ArgumentError)
      expect { Email.mark_as_read! :foo, :bar }.to raise_error(ArgumentError)
    end

    it 'raises for an object of another class' do
      expect { Email.mark_as_read! [email, reader], for: reader }.to raise_error(ArgumentError)
    end

    it 'works with STI readers' do
      Email.mark_as_read! [email], for: Customer.find(sti_reader.id)

      expect(email.unread?(sti_reader)).to be false
    end
  end

  describe '.cleanup_read_marks!' do
    it 'runs the garbage collector' do
      garbage_collector = instance_double(Unread::GarbageCollector, run!: true)
      allow(Unread::GarbageCollector).to receive(:new).with(Email).and_return(garbage_collector)

      Email.cleanup_read_marks!

      expect(garbage_collector).to have_received(:run!)
    end

    it 'raises without a reader class' do
      allow(ReadMark).to receive(:reader_classes).and_return([])

      expect { Email.cleanup_read_marks! }.to raise_error(RuntimeError, 'There is no class using acts_as_reader.')
    end
  end

  describe 'scopes on a relation' do
    it 'can be chained' do
      email.mark_as_read! for: reader

      expect(Email.where(type: 'MultiLevelStiReadable').unread_by(reader)).to eq [sti_email]
      expect(Email.where(type: 'Email').read_by(reader)).to eq [email]
    end
  end
end
