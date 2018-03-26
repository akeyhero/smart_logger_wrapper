require 'logger'
require 'smart_logger_wrapper/utils/path'

class SmartLoggerWrapper < Logger
  module Utils
    module Backtrace
      module_function

      def get_backtrace(start, length = nil)
        # add 1 to `start` because this method dug the backtrace by 1
        backtrace = clean_backtrace(caller_locations(start + 1).map(&:to_s).lazy)
        length == nil ? backtrace.to_a : backtrace.first(length)
      end

      def clean_backtrace(backtrace)
        (
          if defined?(::Rails) && ::Rails.respond_to?(:backtrace_cleaner)
            Rails.backtrace_cleaner.filter(backtrace)
          else
            backtrace
          end
        ).map { |line| Path.trim_dirname(line) }
      end
    end
  end
end
