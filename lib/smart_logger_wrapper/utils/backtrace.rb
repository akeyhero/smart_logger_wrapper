require 'logger'
require 'smart_logger_wrapper/utils/path'

class SmartLoggerWrapper < Logger
  module Utils
    module Backtrace
      module_function

      def get_backtrace(start, length = nil)
        # add 1 to `start` because this method dug the backtrace by 1
        backtrace = clean_backtrace(caller(start + 1))
        length == nil ? backtrace.to_a : backtrace.first(length)
      end

      def clean_backtrace(backtrace, keeps_first: true)
        (
          if defined?(::Rails) && ::Rails.respond_to?(:backtrace_cleaner)
            if keeps_first
              head, *tail = backtrace
              [head] + Rails.backtrace_cleaner.filter(tail)
            else
              Rails.backtrace_cleaner.filter(backtrace)
            end
          else
            backtrace
          end
        ).map { |line| Path.trim_dirname(line) }
      end
    end
  end
end
