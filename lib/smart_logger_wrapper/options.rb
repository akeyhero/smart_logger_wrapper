require 'logger'

class SmartLoggerWrapper < Logger
  module Options
    class ApplicationError < StandardError; end

    # XXX: Be careful! This relies strongly on the implementation of this class
    APPLY_CALLER_STACK_DEPTH = 2

    module_function

    def apply_all!(messages, logger)
      [defined_appenders, defined_taggers, defined_redirectors].flatten.each do |option_key|
        if logger.options.include?(option_key)
          defined_options[option_key].apply!(messages, logger.options[option_key], logger)
        end
      end
    end

    def define_option(option_name, option_object, defined_option_keys)
      key = option_name.to_sym
      defined_option_keys.push(key)
      defined_options.merge!(key => option_object)
    end

    def define_appender(option_name, option_object)
      define_option(option_name, option_object, defined_appenders)
    end

    def define_tagger(option_name, option_object)
      define_option(option_name, option_object, defined_taggers)
    end

    def define_redirector(option_name, option_object)
      define_option(option_name, option_object, defined_redirectors)
    end

    def defined_appenders
      @defined_appenders ||= []
    end

    def defined_taggers
      @defined_taggers ||= []
    end

    def defined_redirectors
      @defined_redirectors ||= []
    end

    def defined_options
      @defined_options ||= {}
    end

    def defined_option?(option_name)
      defined_options.include?(option_name.to_sym)
    end
  end
end

require 'smart_logger_wrapper/options/to'
require 'smart_logger_wrapper/options/append_backtrace'
require 'smart_logger_wrapper/options/with_position'
