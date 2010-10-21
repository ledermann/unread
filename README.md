MarkAsRead
==========

Rails plugin to manage read/unread status of anything you need.


## Features

* Manages unread records for anything you want your users to read (like messages, documents, comments etc.)
* Supports "mark as read" to mark a **single** record as read
* Supports "mark all as read" to mark **all** records as read in a single step
* Gives you a named_scope to get the unread records for a given user
* Needs only one additional database table
* Great performance


## Requirements

* Rails 2.x (tested with Rails 2.3.10 only)
* ActiveRecord (tested with SQLite and MySQL)
* Needs a model _User_ in your application
* Needs a timestamp field in your models (e.g. created_at)


## Installation

    script/plugin install git://github.com/ledermann/mark_as_read.git
    script/generate mark_as_read_migration
    rake db:migrate


## Usage

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


## TODO

* Add more documentation
* Make it ready for Rails 3
* Build a gem


Copyright (c) 2010 Georg Ledermann, released under the MIT license