# Unread

Ruby gem to manage the read/unread status of ActiveRecord objects.

[![Build Status](https://github.com/ledermann/unread/actions/workflows/main.yml/badge.svg?branch=master)](https://github.com/ledermann/unread/actions)
[![Gem Version](https://badge.fury.io/rb/unread.svg)](https://badge.fury.io/rb/unread)

## Features

* Manages unread records for anything that readers (for example users) read, like messages, documents or comments
* Marks a single record as read
* Marks all records as read in one step
* Gives you a scope for the unread records of a reader
* Needs only one additional database table


## Requirements

* Ruby 3.3 or newer
* Rails 8.1 or newer
* MySQL (with the `mysql2` or `trilogy` adapter), PostgreSQL or SQLite
* A timestamp column in your readable models (like `created_at` or `updated_at`) with a database index


## Changelog

https://github.com/ledermann/unread/releases


## Installation

1. Add the gem to your Gemfile and install it:

   ```shell
   bundle add unread
   ```

2. Generate and run the migration:

   ```shell
   bin/rails generate unread:migration
   bin/rails db:migrate
   ```

   If your models use UUID primary keys, add `--primary-key-type=uuid` to the generator command.


## Upgrade from previous releases

If you upgrade from an older release of this gem, read the [upgrade notes](UPGRADE.md) first.


## Usage

```ruby
class User < ApplicationRecord
  acts_as_reader

  # Optional: Allow a subset of users as readers only
  def self.reader_scope
    where(is_admin: true)
  end
end

class Message < ApplicationRecord
  acts_as_readable on: :created_at

  # The `on:` option sets the relevant attribute for comparing timestamps.
  #
  # The default is :updated_at. If you update a record that a reader read,
  # the record is unread again.
  #
  # With :created_at, only new records are unread. If you update a record
  # that a reader read, the record stays read.
  #
  # You can use any other timestamp column as `on:` option.

  # Optional: If a user can see only some messages, return them here.
  # The cleanup with `cleanup_read_marks!` uses this scope.
  def self.read_scope(user)
    user.visible_messages
  end
end

# A new user starts with all existing messages marked as read (see
# "New readers" below). Thus, this example creates the users first.
user1 = User.create!
user2 = User.create!

message1 = Message.create!
message2 = Message.create!

## Get unread messages for a given user
Message.unread_by(user1)
# => [ message1, message2 ]

message1.mark_as_read! for: user1
Message.unread_by(user1)
# => [ message2 ]

message1.read?(user1)
# => true

## Get read messages for a given user
Message.read_by(user1)
# => [ message1 ]

## Get all messages including the read status for a given user
messages = Message.with_read_marks_for(user1)
# => [ message1, message2 ]
messages[0].unread?(user1)
# => false
messages[1].unread?(user1)
# => true

## Get users that have not read a given message
User.have_not_read(message1)
# => [ user2 ]

## Get users that have read a given message
User.have_read(message1)
# => [ user1 ]

## Get all users including their read status for a given message
users = User.with_read_marks_for(message1)
# => [ user1, user2 ]
users[0].have_read?(message1)
# => true
users[1].have_read?(message1)
# => false

## Mark some messages as read: an array or a relation
Message.mark_as_read! [ message2 ], for: user1
Message.where(id: message2.id).mark_as_read! :all, for: user2

## Mark all messages as read
Message.mark_as_read! :all, for: user2
Message.unread_by(user2)
# => [ ]

# Optional: Remove read marks that are no longer necessary
# Run this once a day, for example in a recurring job
Message.cleanup_read_marks!
```

### New readers

A new reader starts with all existing records marked as read. For this, the gem calls the method `setup_new_reader` after it creates the reader. If you want new readers to see all existing records as unread, override the method:

```ruby
class User < ApplicationRecord
  acts_as_reader

  private

  # All existing messages are unread for a new user
  def setup_new_reader; end
end
```

The gem knows a readable class only after Rails loads the class. Without eager loading, which is the default in development, `setup_new_reader` marks only the readable classes that Rails already loaded.

## Getting read/unread stats through a relationship

```ruby
class Document < ApplicationRecord
  has_many :comments
end

class Comment < ApplicationRecord
  acts_as_readable on: :created_at
  belongs_to :document
end

# Get unread comments count for a document
document = Document.find(1)
default_hash = Hash.new { |h, k| h[k] = { unread: 0, total: 0 } }
document.comments.with_read_marks_for(current_user).reduce(default_hash) do |hash, comment|
  hash[comment.id][:unread] += 1 if comment.unread?(current_user)
  hash[comment.id][:total] += 1
  hash
end
# => {20=>{:unread=>1, :total=>10}, 82=>{:unread=>0, :total=>4}
```

The `with_read_marks_for` scope loads the read status in the same query. The `unread?` calls that follow use this result and do not send more queries.

## How does it work?

For each reader, the gem keeps a timestamp and a list of read items. All items older than the timestamp are read. Of the newer items, only the items in the list are read.

The scope `unread_by` does a LEFT JOIN to this list. You can combine it with other scopes.

The list does not grow without limit:

* If a reader marks all items as read, the gem deletes the list and sets the timestamp to the current time.
* If a reader never marks all items as read, the list gets longer with each item that the reader reads. To remove the items that are no longer necessary, run `cleanup_read_marks!` from time to time.

Here is an example of the SQL query:

```ruby
# The user marked all messages as read on 2010-10-20 08:50
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
                    AND read_marks.reader_id = 42
                    AND read_marks.reader_type = 'User'
                    AND read_marks.timestamp >= messages.created_at
WHERE read_marks.id IS NULL
AND messages.created_at > '2010-10-20 08:50:00'
```

## Performance

The query for unread records reads only the records that are newer than the timestamp of the reader. If the timestamp column has an index, the size of the tables has little effect. Without this index, the database reads all records.

Thus, the time depends on the number of records after the timestamp of the reader. This number gets smaller when the reader marks all records as read. `cleanup_read_marks!` also moves the timestamp forward, up to the oldest unread record. If a reader keeps one old record unread, the number stays large.

Some operations take more time:

* `read_by` reads all records of the table.
* `mark_as_read!` with a collection sends two queries for each record.
* `cleanup_read_marks!` sends queries for each reader. Run it in a background job.


## Development

Run the specs and RuboCop. The spec run fails if the line coverage or the branch coverage goes below 100%.

```shell
bundle install
bundle exec rake
```

The specs use SQLite by default. To use another database, set `DB` to `mysql`, `trilogy` or `postgres`. The connection data is in `spec/database.yml`. To use other ports, set `MYSQL_PORT` or `POSTGRES_PORT`.

To test with another Rails version, set `RAILS_VERSION`, for example `RAILS_VERSION=edge`.


Copyright (c) 2010-2026 [Georg Ledermann](https://ledermann.dev) and [contributors](https://github.com/ledermann/unread/graphs/contributors), released under the MIT license
