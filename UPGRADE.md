# Upgrade notes

## Breaking changes with v0.7.0

There are two important changes needing your attention. Please read the following hints carefully!


### Polymorphic readers

The gem accepts any type of classes as reader and it's not limited to `User` class anymore. So you can do stuff like:

```ruby
Customer.have_not_read(message1)
message1.mark_as_read! :for => Customer.find(1)
```

If you are upgrading from v0.6.3 or older, you need to do the following after upgrading:

```shell
rails g unread:polymorphic_reader_migration
rake db:migrate
```

This will alter the `read_marks` table to replace `user` association to a polymorphic association named `reader`. Therefore, `user_id` is going to be renamed to `reader_id` and `reader_type` is going to be added.

This change should not break your code unless you've worked with `ReadMark` model directly.


### Defining reader_scope

The class method `acts_as_reader` doesn't take the option `:scope` anymore. If you have used it, please change this ...

```ruby
class User < ActiveRecord::Base
  acts_as_reader :scope => -> { where(:is_admin => true) }
end
```

... to this

```ruby
class User < ActiveRecord::Base
  acts_as_reader

  def self.reader_scope
    where(:is_admin => true)
  end
end
```
