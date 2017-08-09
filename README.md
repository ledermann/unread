Unread
======

Ruby gem to manage read/unread status of ActiveRecord objects - and it's fast.

[![Build Status](https://travis-ci.org/ledermann/unread.svg?branch=master)](https://travis-ci.org/ledermann/unread)
[![Code Climate](https://codeclimate.com/github/ledermann/unread.svg)](https://codeclimate.com/github/ledermann/unread)
[![Coverage Status](https://coveralls.io/repos/ledermann/unread/badge.svg?branch=master)](https://coveralls.io/r/ledermann/unread?branch=master)

## Features

* Manages unread records for anything you want readers (e.g. users) to read (like messages, documents, comments etc.)
* Supports _mark as read_ to mark a **single** record as read
* Supports _mark all as read_ to mark **all** records as read in a single step
* Gives you a scope to get the unread records for a given reader
* Needs only one additional database table
* Most important: Great performance


## Requirements

* Ruby 2.0.0 or newer
* Rails 3.0 or newer (including Rails 4.x and Rails 5.x)
* MySQL, PostgreSQL or SQLite
* Needs a timestamp field in your models (like created_at or updated_at) with a database index on it


## Changelog

https://github.com/ledermann/unread/releases


## Installation

Step 1: Add this to your Gemfile:

```ruby
gem 'unread'
```

and run

```shell
bundle
```


Step 2: Generate and run the migration:

```shell
rails g unread:migration
rake db:migrate
```

## Upgrade from previous releases

If you upgrade from an older release of this gem, you should read the [upgrade notes](UPGRADE.md).


## Usage

```ruby
class User < ActiveRecord::Base
  acts_as_reader

  # Optional: Allow a subset of users as readers only
  def self.reader_scope
    where(:is_admin => true)
  end
end

class Message < ActiveRecord::Base
  acts_as_readable :on => :created_at
end

message1 = Message.create!
message2 = Message.create!

## Get unread messages for a given user
Message.unread_by(current_user)
# => [ message1, message2 ]

message1.mark_as_read! :for => current_user
Message.unread_by(current_user)
# => [ message2 ]

## Get read messages for a given user
Message.read_by(current_user)
# => [ ]

message1.mark_as_read! :for => current_user
Message.read_by(current_user)
# => [ message1 ]

## Get all messages including the read status for a given user
messages = Message.with_read_marks_for(current_user)
# => [ message1, message2 ]
messages[0].unread?(current_user)
# => false
messages[1].unread?(current_user)
# => true

Message.mark_as_read! :all, :for => current_user
Message.unread_by(current_user)
# => [ ]

Message.read_by(current_user)
# => [ message1, message2 ]

## Get users that have not read a given message
user1 = User.create!
user2 = User.create!

User.have_not_read(message1)
# => [ user1, user2 ]

message1.mark_as_read! :for => user1
User.have_not_read(message1)
# => [ user2 ]

## Get users that have read a given message
User.have_read(message1)
# => [ user1 ]

message1.mark_as_read! :for => user2
User.have_read(message1)
# => [ user1, user2 ]

Message.mark_as_read! :all, :for => user1
User.have_not_read(message1)
# => [ ]
User.have_not_read(message2)
# => [ user2 ]

User.have_read(message1)
# => [ user1, user2 ]
User.have_read(message2)
# => [ user1 ]

## Get all users including their read status for a given message
users = User.with_read_marks_for(message1)
# => [ user1, user2 ]
users[0].have_read?(message1)
# => true
users[1].have_read?(message2)
# => false

## Get when a user read the message
message1.read_at(current_user)
# => 2017-08-08 18:22:10 UTC

# Optional: Cleaning up unneeded markers
# Do this in a cron job once a day
Message.cleanup_read_marks!
```


## How does it work?

The main idea of this gem is to manage a list of read items for every reader **after** a certain timestamp.

The gem defines a scope doing a LEFT JOIN to this list, so your app can get the unread items in a performant manner. Of course, other scopes can be combined.

It will be ensured that the list of read items will not grow up too much:

* If a user uses "mark all as read", his list gets deleted and the timestamp is set to the current time.
* If a user never uses "mark all as read", the list will grow and grow with each item he reads. But there is help: Your app can use a cleanup method which removes unnecessary list items.

Overall, this gem can be used for large data. Please have a look at the generated SQL queries, here is an example:

```ruby
# Assuming we have a user who has marked all messages as read on 2010-10-20 08:50
current_user = User.find(42)

# Get the unread messages for this user
Message.unread_by(current_user)
```

Generated query:

```sql
SELECT messages.*
FROM messages
LEFT JOIN read_marks ON read_marks.readable_type = "Message"
                    AND read_marks.readable_id = messages.id
                    AND read_marks.reader_id = 42
                    AND read_marks.reader_type = 'User'
                    AND read_marks.timestamp >= messages.created_at
WHERE read_marks.id IS NULL
AND messages.created_at > '2010-10-20 08:50:00'
```

Hint: You should add a database index on `messages.created_at`.


Copyright (c) 2010-2017 [Georg Ledermann](http://www.georg-ledermann.de) and [contributors](https://github.com/ledermann/unread/graphs/contributors), released under the MIT license
