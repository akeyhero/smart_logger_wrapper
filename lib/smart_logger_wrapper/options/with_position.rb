require 'smart_logger_wrapper/options/base'
require 'smart_logger_wrapper/utils/path'

class SmartLoggerWrapper
  module Options
    class WithPosition < Base
      include ::SmartLoggerWrapper::Utils::Path

      def initialize(start)
        super()
        @start = start
      end

      def apply!(messages, value = nil)
        return if value == false
        # add 1 to `start` because this method dug the backtrace by 1
        location = caller_locations(@start + 1, 1)
        prefix =
          if location && location.length > 0
            method_name = location[0].label
            path        = trim_dirname(location[0].absolute_path)
            lineno      = location[0].lineno
            "[#{method_name}@#{path}:#{lineno}]"
          else
            nil
          end
        messages.map! { |message| [prefix, message].compact.join(' ') }
      end
    end

    define_tagger :with_position, WithPosition.new(APPLY_CALLER_STACK_DEPTH + 1)
  end
end
