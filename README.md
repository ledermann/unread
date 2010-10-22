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

* Rails 2.x (tested with Rails 2.3.10)
* ActiveRecord (tested with SQLite and MySQL)
* Needs a timestamp field in your models (e.g. created_at) with a database index on it


## Installation

    script/plugin install git://github.com/ledermann/unread.git
    script/generate unread_migration
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


## Similar tools

There a two other gems/plugins doing a similar job:

* http://github.com/jhnvz/mark_as_read
* http://github.com/mbleigh/acts-as-readable

Unfortunately, both of them have a lack of performance, because they calculate the unread records doing a _find(:all)_, which should be avoided for a large amount of records. This plugin is based on a timestamp algorithm and therefore it's very fast.


## TODO

* Add more documentation
* Make it ready for Rails 3
* Build a gem


Copyright (c) 2010 Georg Ledermann, released under the MIT license