require 'test_helper'

class UnreadTest < ActiveSupport::TestCase
  def setup
    @reader = Reader.create! :name => 'David'
    @other_reader = Reader.create :name => 'Matz'
    wait
    @email1 = Email.create!
    wait
    @email2 = Email.create!
  end
  
  def teardown
    Reader.delete_all
    Email.delete_all
    ReadMark.delete_all
  end
  
  def test_schema_has_loaded_correctly
    assert_equal [@email1, @email2], Email.all
  end
  
  def test_readable_classes
    assert_equal [ Email ], ReadMark.readable_classes
  end
  
  def test_reader_class
    assert_equal Reader, ReadMark.reader_class
  end

  def test_scope
    assert_equal [@email1, @email2], Email.unread_by(@reader)
    assert_equal [@email1, @email2], Email.unread_by(@other_reader)
    
    assert_equal 2, Email.unread_by(@reader).count
    assert_equal 2, Email.unread_by(@other_reader).count
    
    assert_raise(ArgumentError) {
      Email.unread_by(42)
    }
  end
  
  def test_with_read_marks_for
    @email1.mark_as_read! :for => @reader
    
    emails = Email.with_read_marks_for(@reader).all

    assert emails[0].read_mark_id.present?
    assert emails[1].read_mark_id.nil?
    
    assert_equal false, emails[0].unread?(@reader)
    assert_equal true, emails[1].unread?(@reader)
  end
  
  def test_scope_after_reset
    @email1.mark_as_read! :for => @reader
    
    assert_equal [@email2], Email.unread_by(@reader)
    assert_equal 1, Email.unread_by(@reader).count
  end

  def test_unread_after_create
    assert_equal true, @email1.unread?(@reader)
    assert_equal true, @email1.unread?(@other_reader)
    
    assert_raise(ArgumentError) {
      @email1.unread?(42)
    }
  end
  
  def test_unread_after_update
    @email1.mark_as_read! :for => @reader
    wait
    @email1.update_attributes! :subject => 'changed'

    assert_equal true, @email1.unread?(@reader)
  end
  
  def test_mark_as_read
    @email1.mark_as_read! :for => @reader
    
    assert_equal false, @email1.unread?(@reader)
    assert_equal [@email2], Email.unread_by(@reader)
    
    assert_equal true, @email1.unread?(@other_reader)
    assert_equal [@email1, @email2], Email.unread_by(@other_reader)
    
    assert_equal 1, @reader.read_marks.single.count
    assert_equal @email1, @reader.read_marks.single.first.readable
  end
  
  def test_mark_as_read_multiple
    assert_equal true, @email1.unread?(@reader)
    assert_equal true, @email2.unread?(@reader)
    
    Email.mark_as_read! [ @email1, @email2 ], :for => @reader
    
    assert_equal false, @email1.unread?(@reader)
    assert_equal false, @email2.unread?(@reader)
  end
  
  def test_mark_as_read_with_marked_all
    wait
    
    Email.mark_as_read! :all, :for => @reader
    @email1.mark_as_read! :for => @reader
    
    assert_equal [], @reader.read_marks.single
  end
  
  def test_mark_as_read_twice
    @email1.mark_as_read! :for => @reader
    @email1.mark_as_read! :for => @reader
    
    assert_equal 1, @reader.read_marks.single.count
  end
  
  def test_mark_all_as_read
    Email.mark_as_read! :all, :for => @reader
    assert_equal Time.now.to_s, @reader.read_mark_global(Email).try(:timestamp).to_s
    
    assert_equal [], @reader.read_marks.single
    assert_equal 0, ReadMark.single.count
    assert_equal 2, ReadMark.global.count
  end
  
  def test_cleanup_read_marks
    assert_equal 0, @reader.read_marks.single.count
    
    @email1.mark_as_read! :for => @reader
    
    assert_equal [@email2], Email.unread_by(@reader)
    assert_equal 1, @reader.read_marks.single.count
    
    Email.cleanup_read_marks!    
    
    @reader.reload
    assert_equal 0, @reader.read_marks.single.count
  end
  
  def test_cleanup_read_marks_not_delete_from_other_readables
    other_read_mark = @reader.read_marks.create! :readable_type => 'Foo', :readable_id => 42, :timestamp => 5.years.ago
    Email.cleanup_read_marks!
    assert_equal true, ReadMark.exists?(other_read_mark.id)
  end
  
  def test_reset_read_marks_for_all
    Email.reset_read_marks!
    
    assert_equal 0, ReadMark.single.count
    assert_equal 2, ReadMark.global.count
  end
  
private
  def wait
    # Skip one second
    now = Time.now + 1.second
    Time.stubs(:now).returns(now)
  end
end