require 'test_helper'

class UnreadTest < ActiveSupport::TestCase
  def setup
    @user = User.create! :name => 'David'
    @other_user = User.create :name => 'Matz'
    wait
    @email1 = Email.create!
    wait
    @email2 = Email.create!
  end
  
  def teardown
    User.delete_all
    Email.delete_all
    ReadMark.delete_all
  end
  
  def test_schema_has_loaded_correctly
    assert_equal [@email1, @email2], Email.all
  end

  def test_scope
    assert_equal [@email1, @email2], Email.unread_by(@user)
    assert_equal [@email1, @email2], Email.unread_by(@other_user)
    
    assert_equal 2, Email.unread_by(@user).count
    assert_equal 2, Email.unread_by(@other_user).count
  end
  
  def test_scope_after_reset
    @email1.mark_as_read! :for => @user
    
    assert_equal [@email2], Email.unread_by(@user)
    assert_equal 1, Email.unread_by(@user).count
  end

  def test_unread_by
    assert_equal true, @email1.unread?(@user)
    assert_equal true, @email1.unread?(@other_user)
  end
  
  def test_unread_after_update
    @email1.mark_as_read! :for => @user
    wait
    @email1.update_attributes! :subject => 'changed'

    assert_equal true, @email1.unread?(@user)
  end
  
  def test_mark_as_read
    @email1.mark_as_read! :for => @user
    
    assert_equal false, @email1.unread?(@user)
    assert_equal [@email2], Email.unread_by(@user)
    
    assert_equal true, @email1.unread?(@other_user)
    assert_equal [@email1, @email2], Email.unread_by(@other_user)
    
    assert_equal 1, @user.read_marks.single.count
    assert_equal @email1, @user.read_marks.single.first.readable
  end
  
  def test_mark_as_read_multiple
    assert_equal true, @email1.unread?(@user)
    assert_equal true, @email2.unread?(@user)
    
    Email.mark_as_read! [ @email1, @email2 ], :for => @user
    
    assert_equal false, @email1.unread?(@user)
    assert_equal false, @email2.unread?(@user)
  end
  
  def test_mark_as_read_with_marked_all
    wait
    
    Email.mark_as_read! :all, :for => @user
    @email1.mark_as_read! :for => @user
    
    assert_equal [], @user.read_marks.single
  end
  
  def test_mark_as_read_twice
    @email1.mark_as_read! :for => @user
    @email1.mark_as_read! :for => @user
    
    assert_equal 1, @user.read_marks.single.count
  end
  
  def test_mark_all_as_read
    Email.mark_as_read! :all, :for => @user
    assert_equal Time.now.to_s, Email.read_mark(@user).timestamp.to_s
    
    assert_equal [], @user.read_marks.single
    assert_equal 0, ReadMark.single.count
    assert_equal 2, ReadMark.global.count
  end
  
  def test_cleanup_read_marks
    assert_equal 0, @user.read_marks.single.count
    
    @email1.mark_as_read! :for => @user
    
    assert_equal [@email2], Email.unread_by(@user)
    assert_equal 1, @user.read_marks.single.count
    
    Email.cleanup_read_marks!    
    
    @user.reload
    assert_equal 0, @user.read_marks.single.count
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