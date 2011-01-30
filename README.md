Unread
======

Rails plugin to manage read/unread status of anything you need - and it's fast.


## Features

* Manages unread records for anything you want your users to read (like messages, documents, comments etc.)
* Supports "mark as read" to mark a **single** record as read
* Supports "mark all as read" to mark **all** records as read in a single step
* Gives you a named_scope to get the unread records for a given user
* Needs only one additional database table
* Most important: Great performance


## Requirements

* Rails >= 2.1 (including Rails 3)
* ActiveRecord (tested with SQLite and MySQL)
* Needs a timestamp field in your models (e.g. created_at) with a database index on it


## Installation

Install from Github:

    Rails 2: script/plugin install git://github.com/ledermann/unread.git
    Rails 3: rails plugin install git://github.com/ledermann/unread.git
    
Add this migration:
    
    class CreateReadMarks < ActiveRecord::Migration
      def self.up
        create_table :read_marks, :force => true do |t|
          t.integer  :readable_id
          t.integer  :user_id,       :null => false
          t.string   :readable_type, :null => false, :limit => 20
          t.datetime :timestamp
        end
        add_index :read_marks, [:user_id, :readable_type, :readable_id]
      end

      def self.down
        drop_table :read_marks
      end
    end

Run the migration:
    
    rake db:migrate


## Usage

    class User < ActiveRecord::Base
      acts_as_reader
    end
    
    class Message < ActiveRecord::Base
      acts_as_readable :on => :created_at
    end

    message1 = Message.create!
    message2 = Message.create!
    
    Message.unread_by(current_user)
    # => [ message1, message2 ]
    
    message1.mark_as_read! :for => current_user
    Message.unread_by(current_user)
    # => [ message2 ]
    
    Message.mark_as_read! :all, :for => current_user
    Message.unread_by(current_user)
    # => [ ]
    
    # Optional: Cleaning up unneeded markers
    # Do this in a cron job once a day.
    Message.cleanup_read_marks!


## How does it work?

The main idea of this plugin is to manage a list of read items for every user **after** a certain timestamp.

The plugin defines a named_scope doing a LEFT JOIN to this list, so your app can get the unread items in a performant manner. Of course, other scopes can be combined.

It will be ensured that the list of read items will not grow up too much:

* If a user uses "mark all as read", his list is deleted and the timestamp is set to the current time.
* If a user never uses "mark all as read", the list will grow and grow with each item he reads. But there is help: Your app can use a cleanup method which removes unnecessary list items.

Overall, this plugin can be used for large tables, too. If you are in doubt, look at the generated SQL queries, here is an example:

    # Assuming we have a user who has marked all messages as read on 2010-10-20 08:50
    current_user = User.find(42) 
    
    # Get the unread messages for this user
    Message.unread_by(current_user)
    
    # => 
    #     SELECT messages.* 
    #     FROM messages
    #     LEFT JOIN read_marks ON read_marks.readable_type = 'Message'
    #                         AND read_marks.readable_id = messages.id
    #                         AND read_marks.user_id = 42
    #                         AND read_marks.timestamp >= messages.created_at 
    #     WHERE read_marks.id IS NULL 
    #     AND messages.created_at > '2010-10-20 08:50:00'

    Hint: You should add a database index on messages.created_at.


## Similar tools

There a two other gems/plugins doing a similar job:

* http://github.com/jhnvz/mark_as_read
* http://github.com/mbleigh/acts-as-readable

Unfortunately, both of them have a lack of performance, because they calculate the unread records doing a _find(:all)_, which should be avoided for a large amount of records. This plugin is based on a timestamp algorithm and therefore it's very fast.


## TODO

* Add more documentation
* Build a gem


Copyright (c) 2010,2011 Georg Ledermann, released under the MIT license