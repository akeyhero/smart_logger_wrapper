require 'logger'
require 'smart_logger_wrapper/options/base'
require 'smart_logger_wrapper/utils/path'
require 'smart_logger_wrapper/utils/backtrace'

class SmartLoggerWrapper < Logger
  module Options
    class WithPosition < Base
      include ::SmartLoggerWrapper::Utils::Path
      include ::SmartLoggerWrapper::Utils::Backtrace

      def apply!(messages, arguments, severity, wrapper)
        enabled = arguments.first || true
        return unless enabled
        # add 1 to `start` because this method dug the backtrace by 1
        location = caller_locations(wrapper.offset + APPLY_CALLER_STACK_DEPTH + 1, 1)
        prefix =
          if location && location.length > 0 && location_important?(location)
            method_name = location[0].label
            path        = trim_dirname(location[0].absolute_path)
            lineno      = location[0].lineno
            "[#{method_name}@#{path}:#{lineno}]"
          else
            nil
          end
        messages.map! { |message| [prefix, message].compact.join(' ') }
      end

      private

      def location_important?(location)
        ! clean_backtrace(location.map(&:to_s), keeps_first: false).empty?
      end
    end

    define_tagger :with_position, WithPosition
  end
end
