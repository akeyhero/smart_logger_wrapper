require 'logger'
require 'smart_logger_wrapper/options/base'

class SmartLoggerWrapper < Logger
  module Options
    class To < Base
      def apply!(messages, arguments, severity, wrapper)
        raise ApplicationError, 'No handler given' if arguments.empty?
        out = arguments.first
        time = Time.now
        severity_label = wrapper.format_severity(severity)
        out.puts messages.map { |message| wrapper.format_message(severity_label, time, nil, message) }.join("\n")
      rescue NoMethodError => e
        raise ApplicationError, e.message
      end
    end

    define_redirector :to, To
  end
end
