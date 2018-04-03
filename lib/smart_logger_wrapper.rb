require 'logger'
require 'smart_logger_wrapper/version'
require 'smart_logger_wrapper/options'

class SmartLoggerWrapper < Logger
  include Logger::Severity

  LOGGER_SHORTCUT_OFFSET = 3

  SEVERITY_MAPPING = {
    debug:   DEBUG,
    info:    INFO,
    warn:    WARN,
    error:   ERROR,
    fatal:   FATAL,
    unknown: UNKNOWN
  }.freeze
  DELEGETING_METHODS = %i(<< reopen close log add level debug? level= progname datetime_format= datetime_format formatter sev_threshold sev_threshold= info? warn? error? fatal? progname= formatter=)

  attr_reader :loggers, :options, :offset

  def initialize(logger = Logger.new(STDOUT), *loggers, **options)
    @loggers = [logger, *loggers].freeze
    @options = options.freeze
    @offset = LOGGER_SHORTCUT_OFFSET
    @_loggers_cache = {}
    @_loggers_with_offset_cache = {}
  end

  # For all methods with severity label, logger accepts multiple messages.
  # The return value is the first one of the first logger's.
  SEVERITY_MAPPING.each do |severity_name, severity|
    define_method(severity_name) do |*args, &block|
      build_messages(severity, *args, &block).map do |message|
        loggers.map do |logger|
          logger.public_send(severity_name, message)
        end.first
      end.first
    end
  end

  # Aside from #debug, #info, etc., all Logger instance methods are called for all the wrapped loggers.
  # The return value is the first logger's.
  DELEGETING_METHODS.each do |method_name|
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

  def format_severity(severity)
    loggers.first.send(:format_severity, severity)
  end

  def format_message(severity, datetime, progname, msg)
    loggers.first.send(:format_message, severity, datetime, progname, msg)
  end

  private

  def build_messages(severity, *args, &block)
    messages = args.map { |arg| to_message(arg) }
    messages << to_message(block.call) if block_given?
    begin
      Options.apply_all!(messages, severity, self)
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
      arg = args.first
      @_loggers_cache[method_name] = {} unless @_loggers_cache.include?(method_name)
      new_logger = @_loggers_cache[method_name][arg] ||= clone.tap do |cloned|
        cloned.overwrite_options(method_name => arg)
      end
      return block.(new_logger) if block_given?
      new_logger
    else
      super
    end
  end
end
