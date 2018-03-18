class SmartLoggerWrapper
  module Options
    class Base
      def apply!(messages, value)
        raise NotImplementedError, __callee__
      end
    end
  end
end

