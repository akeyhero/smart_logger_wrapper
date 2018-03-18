require 'smart_logger_wrapper/options/base'

class SmartLoggerWrapper
  module Options
    class To < Base
      def apply!(messages, value)
        return if value == nil
        value.puts messages.join("\n")
      rescue NoMethodError => e
        raise ApplicationError, e.message
      end
    end

    define_redirector :to, To.new
  end
end
