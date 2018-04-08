require 'logger'
require 'smart_logger_wrapper/version'
require 'smart_logger_wrapper/options'

class SmartLoggerWrapper < Logger
  include Logger::Severity

  BASE_OFFSET = 3
  NESTED_WRAPPER_OFFSET = 6

  SEVERITY_MAPPING = {
    debug:   DEBUG,
    info:    INFO,
    warn:    WARN,
    error:   ERROR,
    fatal:   FATAL,
    unknown: UNKNOWN
  }.freeze
  DELEGETING_METHODS = %i(<< reopen close log add level debug? level= progname datetime_format= datetime_format formatter sev_threshold sev_threshold= info? warn? error? fatal? progname= formatter=).freeze

  attr_reader :loggers, :options, :base_offset, :parent

  def initialize(logger = Logger.new(STDOUT), *loggers, base_offset: nil, parent: nil, **options)
    @base_offset = base_offset || BASE_OFFSET
    @parent = parent
    @loggers = be_parent_of!(logger, *loggers).freeze
    @options = options.freeze
    @_loggers_cache = {}
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

  def offset
    @base_offset + depth * NESTED_WRAPPER_OFFSET
  end

  def depth
    return 0 if root?
    parent.depth + 1
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

  def set_parent!(new_parent)
    @_loggers_cache.clear if new_parent != nil
    @parent = new_parent == self ? nil : new_parent # to avoid stack overflow at #depth
  end

  def be_parent_of!(*loggers)
    loggers.each do |logger|
      # XXX: Calling a private method because it is an internal procedure
      logger.is_a?(SmartLoggerWrapper) ? logger.send(:set_parent!, self) : logger
    end
  end

  def root?
    parent == nil
  end

  def method_missing(method_name, *args, &block)
    if root? && Options.defined_option?(method_name)
      # When the root wrapper receive an defined option with the same name as the method name,
      # return a new logger wrapper with the option.
      arg = args.first
      @_loggers_cache[method_name] = {} unless @_loggers_cache.include?(method_name)
      logger_with_option = @_loggers_cache[method_name][arg] ||= self.class.new(
        *loggers,
        base_offset: base_offset,
        **options.merge(method_name => arg)
      )
      return block.(logger_with_option) if block_given?
      logger_with_option
    else
      super
    end
  end

  def respond_to_missing?(method_name, includes_private)
    root? && Options.defined_option?(method_name) || super
  end
end
