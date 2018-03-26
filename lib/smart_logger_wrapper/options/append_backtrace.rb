require 'logger'
require 'smart_logger_wrapper/options/base'
require 'smart_logger_wrapper/utils/backtrace'

class SmartLoggerWrapper < Logger
  module Options
    class AppendBacktrace < Base
      include ::SmartLoggerWrapper::Utils::Backtrace

      def apply!(messages, value, logger)
        length = value.is_a?(Numeric) ? value : nil
        messages << [
          'BACKTRACE:',
          *get_backtrace(logger.offset + APPLY_CALLER_STACK_DEPTH + 1, length)
        ].join("\n")
      end
    end

    define_appender :append_backtrace, AppendBacktrace.new
  end
end
