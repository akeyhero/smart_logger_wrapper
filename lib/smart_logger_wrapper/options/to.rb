require 'logger'
require 'smart_logger_wrapper/options/base'

class SmartLoggerWrapper < Logger
  module Options
    class To < Base
      def apply!(messages, argument, severity, wrapper)
        raise ApplicationError, 'No handler given' if argument == nil
        argument.puts messages.join("\n")
      rescue NoMethodError => e
        raise ApplicationError, e.message
      end
    end

    define_redirector :to, To
  end
end
