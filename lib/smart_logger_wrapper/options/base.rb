require 'logger'

class SmartLoggerWrapper < Logger
  module Options
    class Base
      def apply!(messages, arguments, severity, wrapper)
        raise NotImplementedError, __callee__
      end
    end
  end
end

