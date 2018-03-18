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

  attr_reader :logger, :options

  def initialize(logger = Logger.new(STDOUT), **options)
    @logger = logger
    @options = options
  end

  def log(severity, *args, &block)
    _log(severity, *args, &blank)
  end
  alias add log

  SEVERITY_MAPPING.each do |severity_name, severity|
    define_method(severity_name) do |*args, &block|
      _log(severity, *args, &block)
    end
  end

  private

  # All methods calling this must have the synchronized call stack depth so that this can show neat positions and backtraces
  def _log(severity, *args, &block)
    messages = args.map { |arg| to_message(arg) }
    messages << to_message(block.call) if block_given?
    Options.apply_all!(messages, options)
    messages.each do |message|
      logger.log(severity, nil, message)
    end
    true
  rescue Options::ApplicationError => e
    logger.error(<<~EOM)
      #{e.inspect}
      #{e.backtrace.join("\n")}
    EOM
    false
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
      new_logger = self.class.new(logger, **options.merge(method_name => args.first))
      return block.(new_logger) if block_given?
      new_logger
    else
      logger.public_send(method_name, *args, &block)
    end
  end
end
