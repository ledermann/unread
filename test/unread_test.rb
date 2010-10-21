require 'test_helper'

class UnreadTest < ActiveSupport::TestCase
  def setup
    @user = User.create! :name => 'David'
    @other_user = User.create :name => 'Matz'
    wait
    @email = Email.create!
  end
  
  def teardown
    User.delete_all
    Email.delete_all
    ReadMark.delete_all
  end
  
  def test_schema_has_loaded_correctly
    assert_equal [@email], Email.all
  end

  def test_scope
    assert_equal [@email], Email.unread_by(@user)
    assert_equal [@email], Email.unread_by(@other_user)
    
    assert_equal 1, Email.unread_by(@user).count
    assert_equal 1, Email.unread_by(@other_user).count
  end
  
  def test_scope_after_reset
    @email.mark_as_read! :for => @user
    second_mail = Email.create! :updated_at => Time.now
    
    assert_equal [second_mail], Email.unread_by(@user)
    assert_equal 1, Email.unread_by(@user).count
  end

  def test_unread_by
    assert_equal true, @email.unread?(@user)
    assert_equal true, @email.unread?(@other_user)
  end
  
  def test_unread_after_update
    @email.mark_as_read! :for => @user
    wait
    @email.update_attributes! :subject => 'changed'

    assert_equal true, @email.unread?(@user)
  end
  
  def test_mark_as_read
    @email.mark_as_read! :for => @user
    
    assert_equal false, @email.unread?(@user)
    assert_equal [], Email.unread_by(@user)
    
    assert_equal true, @email.unread?(@other_user)
    assert_equal [@email], Email.unread_by(@other_user)
    
    assert_equal 1, @user.read_marks.read.count
    assert_equal @email, @user.read_marks.read.first.readable
  end
  
  def test_mark_as_read_multiple
    other_mail = Email.create! :updated_at => Time.now
    
    assert_equal true, @email.unread?(@user)
    assert_equal true, other_mail.unread?(@user)
    
    Email.mark_as_read! [ @email.id, other_mail.id ], :for => @user
    
    assert_equal false, @email.unread?(@user)
    assert_equal false, other_mail.unread?(@user)
  end
  
  def test_mark_as_read_with_marked_all
    wait
    
    Email.mark_as_read! :all, :for => @user
    @email.mark_as_read! :for => @user
    
    assert_equal [], @user.read_marks.read
  end
  
  def test_mark_as_read_twice
    @email.mark_as_read! :for => @user
    @email.mark_as_read! :for => @user
    
    assert_equal 1, @user.read_marks.read.count
  end
  
  def test_mark_all_as_read
    Email.mark_as_read! :all, :for => @user
    assert_equal Time.now.to_s, Email.global_read_mark(@user).timestamp.to_s
    
    assert_equal [], @user.read_marks.read
    assert_equal 0, ReadMark.read.count
    assert_equal 2, ReadMark.global.count
  end
  
  def test_cleanup_read_marks
    Email.cleanup_read_marks!
  end
  
  def test_reset_read_marks_for_all
    Email.reset_read_marks!
    
    assert_equal 0, ReadMark.read.count
    assert_equal 2, ReadMark.global.count
  end
  
private
  def wait
    # Skip one second
    now = Time.now + 1.second
    Time.stubs(:now).returns(now)
  end
end