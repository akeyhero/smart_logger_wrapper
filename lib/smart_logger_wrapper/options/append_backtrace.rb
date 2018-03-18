require 'smart_logger_wrapper/options/base'
require 'smart_logger_wrapper/utils/backtrace'

class SmartLoggerWrapper
  module Options
    class AppendBacktrace < Base
      include ::SmartLoggerWrapper::Utils::Backtrace

      def initialize(start)
        super()
        @start = start
      end

      def apply!(messages, value = nil)
        length = value.is_a?(Numeric) ? value : nil
        messages << "BACKTRACE:\n" + get_backtrace(@start + 1, length).join("\n")
      end
    end

    define_appender :append_backtrace, AppendBacktrace.new(APPLY_CALLER_STACK_DEPTH + 1)
  end
end
