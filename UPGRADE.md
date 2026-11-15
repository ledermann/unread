# Upgrade notes

## Upgrade to v1.0.0

### Ruby and Rails versions

The gem supports only Ruby and Rails versions that still get security fixes:

* Ruby 3.3 or newer
* Rails 8.1 or newer

If your app uses an older version, stay on v0.14.0.

### Public API

The gem adds fewer methods to your models. These methods are the public API:

* Reader class: `acts_as_reader`, `have_read`, `have_not_read`, `with_read_marks_for`, `reader_scope`
* Reader instance: `have_read?`, `read_mark_global`
* Readable class: `acts_as_readable`, `unread_by`, `read_by`, `with_read_marks_for`, `mark_as_read!`, `cleanup_read_marks!`, `read_scope`, `readable_options`
* Readable instance: `unread?`, `read?`, `mark_as_read!`

The other methods are now private or moved to `Unread::Internal`:

* `join_read_marks`
* `mark_collection_as_read` and `mark_collection_item_as_read`
* `reset_read_marks_for_user`: Use `mark_as_read!(:all, for: reader)`.
* `readable_parent`
* `assert_reader`, `assert_reader_class` and `assert_readable`
* `forget_memoized_read_mark_global`: Use `reload` on the reader. It also clears the memoized global read mark.
* `using_postgresql?`

If your app calls one of these methods, change it before you upgrade.

### Migration generator

The generator `unread:migration` changed for new installations:

* The migration uses the current Rails migration version and a `change` method.
* On MySQL, the table uses the default character set of the database. The old migration set `latin1`.
* The column `reader_id` is `NOT NULL`.

You do not have to change existing `read_marks` tables.

The generator `unread:polymorphic_reader_migration` was removed. If you upgrade from v0.6.3 or older, upgrade to v0.14.0 first. Then follow the [upgrade notes of v0.14.0](https://github.com/ledermann/unread/blob/v0.14.0/UPGRADE.md).
