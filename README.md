Unread
======

Ruby gem to manage read/unread status of ActiveRecord objects - and it's fast.

[![Build Status](https://travis-ci.org/ledermann/unread.svg?branch=master)](https://travis-ci.org/ledermann/unread)
[![Code Climate](https://codeclimate.com/github/ledermann/unread.svg)](https://codeclimate.com/github/ledermann/unread)
[![Coverage Status](https://coveralls.io/repos/ledermann/unread/badge.svg?branch=master)](https://coveralls.io/r/ledermann/unread?branch=master)

## Features

* Manages unread records for anything you want users to read (like messages, documents, comments etc.)
* Supports _mark as read_ to mark a **single** record as read
* Supports _mark all as read_ to mark **all** records as read in a single step
* Gives you a scope to get the unread records for a given user
* Needs only one additional database table
* Most important: Great performance


## Requirements

* Ruby 1.9.3 or newer
* Rails 3 (including 3.0, 3.1, 3.2) and Rails 4. For use with Rails 2.3 there is a branch named "rails2"
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


## Usage

```ruby
class User < ActiveRecord::Base
  acts_as_reader
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
# => [ ]

message1.mark_as_read! :for => user1
User.have_read(message1)
# => [ user1 ]

Message.mark_as_read! :all, :for => user1
User.have_not_read(message1)
# => [ user2 ]
User.have_not_read(message2)
# => [ user2 ]

User.have_read(message1)
# => [ user1 ]
User.have_read(message2)
# => [ user1 ]

# Optional: Cleaning up unneeded markers.
# Do this in a cron job once a day.
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
LEFT JOIN read_marks ON read_marks.readable_type = 'Message'
                    AND read_marks.readable_id = messages.id
                    AND read_marks.user_id = 42
                    AND read_marks.timestamp >= messages.created_at
WHERE read_marks.id IS NULL
AND messages.created_at > '2010-10-20 08:50:00'
```

Hint: You should add a database index on `messages.created_at`.


## Similar tools

There are two other gems/plugins doing a similar job:

* http://github.com/jhnvz/mark_as_read
* http://github.com/mbleigh/acts-as-readable

Unfortunately, both of them have a lack of performance, because they calculate the unread records doing a `find(:all)`, which should be avoided for a large amount of records. This gem is based on a timestamp algorithm and therefore it's very fast.


Copyright (c) 2010-2015 [Georg Ledermann](http://www.georg-ledermann.de), released under the MIT license
