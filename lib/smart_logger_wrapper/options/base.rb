require 'logger'

class SmartLoggerWrapper < Logger
  module Options
    class Base
      def apply!(messages, value, logger)
        raise NotImplementedError, __callee__
      end
    end
  end
end

