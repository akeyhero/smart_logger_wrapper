# SmartLoggerWrapper

SmartLoggerWrapper adds some useful features to the Ruby Logger or the compatibles. See Usage below to find out how it benefits your development.

[![Build Status](https://travis-ci.org/akeyhero/smart_logger_wrapper.svg?branch=master)](https://travis-ci.org/akeyhero/smart_logger_wrapper)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'smart_logger_wrapper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install smart_logger_wrapper

## Usage

### Basic

Initialize with a Ruby `Logger` or an instance of the compatibles (e.g. `ActiveSupport::TaggedLogging`):

```ruby
require 'logger'
require 'smart_logger_wrapper'

logger = SmartLoggerWrapper.new(Logger.new('log/development.log'))

logger.info 'Call logging methods as usual.'
```

The compatibles must respond to `#log` with the same arguments as `Logger#log`.

### Feature 1: Integrate multiple logger calls

`SmartLoggerWrapper` accepts multiple arguments like `puts` method does. Then the wrapped logger will be called for each of the arguments.

```ruby
logger.info 'foo', 'bar'
# => I, [2018-03-19T03:03:52.525503 #92534]  INFO -- : foo
# => I, [2018-03-19T03:03:52.527478 #92534]  INFO -- : bar
```

### Feature 2: Better exception logging

When you pass an exception to this logger, it logs the backtrace of the exception along with the message.

```ruby
logger.error ex
# => E, [2018-03-19T02:53:01.605740 #92534] ERROR -- : #<RuntimeError: an error>
# => path/to/code.rb:6:in `foo'
# => path/to/code.rb:2:in `bar'
```

### Feature 3: Optional modifiers

You can chain options to the logger instance to modify logging messages.

```ruby
logger.with_position.to(STDERR).info 'A message'

# You can use blocks to log several times with the same options.
logger.with_position do |logger_with_pos|
  logger_with_pos.info 'A message'
  logger_with_pos.append_backtrace.error 'An error'
end
```

#### #to

With `to` option, this logger leaves your messages to another location besides the original where the wrapped logger logs.

```ruby
logger.to(STDERR).info 'A message'
```

#### #with\_position

`with_position` option makes the logger tag the position where the logger is called.

```ruby
logger.with_position.info 'A message'
# => I, [2018-03-19T03:34:10.448542 #92534]  INFO -- : [path/to/caller.rb@foo:2] A message

# You can turn off this option by chaining #with_position with false
logger.with_position.with_position(false).info 'A message'
```

#### #append\_backtrace

With `append_backtrace`, the logger adjoins its caller's backtrace.

```ruby
logger.append_backtrace.info 'A message'
# => I, [2018-03-19T03:44:36.987404 #97956]  INFO -- : A message
# => I, [2018-03-19T03:44:36.987530 #97956]  INFO -- : BACKTRACE:
# => path/to/code.rb:6:in `foo'
# => path/to/code.rb:2:in `bar'

# You can specify the length of the backtrace
logger.append_backtrace(2).info 'A message'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/akeyhero/smart_logger_wrapper.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
