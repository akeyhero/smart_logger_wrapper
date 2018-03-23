require 'logger'
require 'smart_logger_wrapper/version'
require 'smart_logger_wrapper/options'

class SmartLoggerWrapper
  include Logger::Severity

  SEVERITY_MAPPING = {
    debug:   DEBUG,
    info:    INFO,
    warn:    WARN,
    error:   ERROR,
    fatal:   FATAL,
    unknown: UNKNOWN
  }.freeze

  attr_reader :loggers, :options

  def initialize(logger = Logger.new(STDOUT), *loggers, **options)
    @loggers = [logger, *loggers]
    @options = options
  end

  def add(severity, *args, &block)
    _add(severity, *args, &block)
  end
  alias log add

  SEVERITY_MAPPING.each do |severity_name, severity|
    define_method(severity_name) do |*args, &block|
      _add(severity, *args, &block)
    end
  end

  private

  # All methods calling this must have the synchronized call stack depth so that this can show neat positions and backtraces
  def _add(severity, *args, &block)
    messages = args.map { |arg| to_message(arg) }
    messages << to_message(block.call) if block_given?
    begin
      Options.apply_all!(messages, options)
      true
    rescue Options::ApplicationError => e
      loggers.each do |logger|
        logger.error(<<~EOM)
          Failed to apply options: #{e.inspect}
          #{e.backtrace.join("\n")}
        EOM
      end
      false
    end.tap do |succeeded|
      messages.each do |message|
        loggers.each do |logger|
          logger.add(severity, nil, message)
        end
      end
    end
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
      new_logger = self.class.new(*loggers, **options.merge(method_name => args.first))
      return block.(new_logger) if block_given?
      new_logger
    else
      # Otherwise, call the method of the warpped logger.
      # The reutrn value is that of the first one.
      loggers.map do |logger|
        logger.public_send(method_name, *args, &block)
      end.first
    end
  end
end
