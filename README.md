# SmartLoggerWrapper

SmartLoggerWrapper adds some useful features to the Ruby Logger or its subclasses. See Usage below to find out how it benefits your development.

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

### For Ruby on Rails

Wrap your logger with `SmartLoggerWrapper`, for example, in `config/environments/production.rb`:

```diff
-  config.logger = Logger.new('log/production.log', 'daily')
+  config.logger = SmartLoggerWrapper.new(Logger.new('log/production.log', 'daily')).with_position
```

Note that it is strongly recommended to use the wrapper for all kind of environments so that you can avoid exceptions such as `NoMethodError` due to the unique features of this library.

You may want to put log messages to `STDERR` in your development environment. Then:

```ruby
  config.logger = SmartLoggerWrapper.new(
    SmartLoggerWrapper.new(Logger.new("log/development.log")).with_position,
    ActiveSupport::Logger.new(STDERR)
  )
```

## Usage

### Basic

This wrapper mainly modifies the behaviors of the following methods: `debug`, `info`, `warn`, `error`, `fatal`, and `unknown`.

To use this wrapper, initialize with a Ruby `Logger` or an instance of its subclass:

```ruby
require 'logger'
require 'smart_logger_wrapper'

logger = SmartLoggerWrapper.new(Logger.new('log/development.log'))

logger.info 'Call logging methods as usual.'

# You can wrap multiple loggers
logger2 = SmartLoggerWrapper.new(Logger.new('log/development.log'), Logger.new(STDOUT))
```

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
logger.with_position do |pos_logger|
  pos_logger.info 'A message'
  pos_logger.append_backtrace.error 'An error'
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

# You can specify the length of the backtrace to log
logger.append_backtrace(2).info 'A message'
```

### Define your own options

You can define a new option by your own.

For instance, in the case you want to integrate a messenger, such as Slack, in a Rails app, you will define an initializer like this:

`config/initializers/some_messenger_integration.rb`

```ruby
SmartLoggerWrapper::Options.define_redirector :to_messenger, Class.new(SmartLoggerWrapper::Options::Base) {
  def apply!(messages, arguments, severity, wrapper)
    channel = arguments.first || 'general'
    time = Time.now
    severity_label = wrapper.format_severity(severity)
    formatted_messages = messages.map { |message| wrapper.format_message(severity_label, time, nil, message) }
    Thread.new do
      SomeMessenger.new(channel: channel).post(['```', *formatted_messages, '```'].join("\n"))
    end
  end
}
```

Then, you can post log messages as follows:

```ruby
Rails.logger.to_messenger('channel').error('foo')
```

#### Implementation

Eash option is expected to be defined with a subclass of `SmartLoggerWrapper::Options::Base`. The class is required to respond to `#apply!` with the following arguments: `messages`, `argument`, `severity` and `wrapper`. Firstly, `messages` is an array of messages to be logged. In the case that you want to update the messages, you need to destructively update the array (because of its performance). Second, `argument` is the one which is passed as the option method argument. `severity` is an integer in response to `Logger::Severity`. Lastly, `wrapper` is the caller `SmartLoggerWrapper`.

#### Option priority

There are three categories for `SmartLoggerWrapper::Options`. Each option will be applied in the following order according to its category:

##### 1. Tagger

A tagger is expected to be used to tag each message. To define a tagger, you will call `SmartLoggerWrapper::Options.define_tagger`.

##### 2. Appender

An appender is expected to append some additinal information to the message list. To define an appender, you will call `SmartLoggerWrapper::Options.define_appender`.

##### 3. Redirector

A redirector should put messages to another location from the one where the wrapped logger specifies. To define a redirector, you will call `SmartLoggerWrapper::Options.define_redirector`.

Indeed, these categories don't restrict how you implement your options. You can, for example, tag messages with a redirector in your responsibility.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/akeyhero/smart_logger_wrapper.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
