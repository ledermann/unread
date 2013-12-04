# Changelog

## 0.3.1 - 2013-12-04

* Use Time.current instead of Time.now to avoid time zone trouble. Issue #18 (thanks to @henrythe9th)
* Improve caching for read_mark_global. Issue #22 (thanks to @simpl1g)
* Handle primary keys other than "id". Issue #29 (thanks to @bcavileer)


## 0.3.0 - 2013-03-17

* Support for Rails 4 (beta1)


## 0.2.0 - 2013-02-18

* Support for Rails 2 dropped
* Refactoring
* Added migration generator


## 0.1.2 - 2013-01-27

* Scopes: Improved parameter check


## 0.1.1 - 2012-05-01

* Fixed handling namespaced classes. Closes #10 (thanks to @stanislaw)


## 0.1.0 - 2012-04-21

* Added scope "with_read_marks_for"
* Fixed #7: Added attr_accessible to all ReadMark attributes (thanks to @negative)


## 0.0.7 - 2012-02-29

* Cleanup files
* acts_as_reader: Using inverse_of (available since Rails 2.3.6)


## 0.0.6 - 2011-11-11

* Fixed #5: Gemspec dependency fix (thanks to @bricker88)
* Fixed #6: Removed hard coded dependency on a class named "User" (thanks to @mixandgo)
* Some cleanup


## 0.0.5 - 2011-09-09

* Fixed class loading issue in development environment


## 0.0.4 - 2011-08-31

* Ignore multiple calls of acts_as_*
* Improved error messages
* Tested with Rails 3.1


## 0.0.3 - 2011-08-01

* Fixed gemspec by adding development dependencies
* Testing with Travis CI


## 0.0.2 - 2011-06-23

* Fixed scoping for ActiveRecord 2.x


## 0.0.1 - 2011-06-23

* Released as Gem
