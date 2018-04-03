require 'logger'
require 'smart_logger_wrapper/options/base'

class SmartLoggerWrapper < Logger
  module Options
    class To < Base
      def apply!(messages, argument, severity, wrapper)
        raise ApplicationError, 'No handler given' if argument == nil
        time = Time.now
        severity_label = wrapper.format_severity(severity)
        argument.puts messages.map { |message| wrapper.format_message(severity_label, time, nil, message) }.join("\n")
      rescue NoMethodError => e
        raise ApplicationError, e.message
      end
    end

    define_redirector :to, To
  end
end
