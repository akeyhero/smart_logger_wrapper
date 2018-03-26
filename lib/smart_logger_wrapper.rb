require 'logger'
require 'smart_logger_wrapper/version'
require 'smart_logger_wrapper/options'

class SmartLoggerWrapper < Logger
  include Logger::Severity

  SEVERITY_MAPPING = {
    debug:   DEBUG,
    info:    INFO,
    warn:    WARN,
    error:   ERROR,
    fatal:   FATAL,
    unknown: UNKNOWN
  }.freeze

  attr_reader :loggers, :options, :offset

  def initialize(logger = Logger.new(STDOUT), *loggers, **options)
    @loggers = [logger, *loggers].freeze
    @options = options.freeze
    @offset = 3
    @_loggers_cache = {}
    @_loggers_with_offset_cache = {}
  end

  # For all methods with severity label, logger accepts multiple messages.
  # The return value is the first logger's.
  SEVERITY_MAPPING.each do |severity_name, severity|
    define_method(severity_name) do |*args, &block|
      format_messages(*args, &block).map do |message|
        add(severity, nil, message)
      end.first
    end
  end

  # Aside from #debug, #info, etc., all Logger instance methods are called for all the wrapped loggers.
  # The return value is the first logger's.
  (Logger.instance_methods(false) - SEVERITY_MAPPING.keys).each do |method_name|
    define_method(method_name) do |*args, &block|
      loggers.map do |logger|
        logger.public_send(method_name, *args, &block)
      end.first
    end
  end

  def with_offset(_offset)
    @_loggers_with_offset_cache[_offset] ||= clone.tap do |logger_with_offset|
      logger_with_offset.instance_variable_set(:@offset, _offset)
    end
  end

  def overwrite_options(_options)
    @options = options.merge(_options).freeze
  end

  private

  def format_messages(*args, &block)
    messages = args.map { |arg| to_message(arg) }
    messages << to_message(block.call) if block_given?
    begin
      Options.apply_all!(messages, self)
    rescue Options::ApplicationError => e
      loggers.each do |logger|
        logger.error(<<~EOM)
          Failed to apply options: #{e.inspect}
          #{e.backtrace.join("\n")}
        EOM
      end
    end
    messages
  end

  def to_message(object)
    case object
    when String
      object
    when Exception
      backtrace = object.backtrace ? Utils::Backtrace.clean_backtrace(object.backtrace) : []
      info = [object.inspect]
      (info + backtrace).join("\n")
    else
      object.inspect
    end
  end

  def method_missing(method_name, *args, &block)
    if Options.defined_option?(method_name)
      # If there is an defined option with the same name as the method name, return a new logger with the option.
      new_logger = @_loggers_cache[method_name] ||= clone.tap do |cloned|
        cloned.overwrite_options(method_name => args.first)
      end
      return block.(new_logger) if block_given?
      new_logger
    else
      super
    end
  end
end
