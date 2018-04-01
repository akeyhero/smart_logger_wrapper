require 'logger'

class SmartLoggerWrapper < Logger
  module Utils
    module Path
      DIR_TRIMMER_PATTERN = /^#{Dir.pwd}\/?/

      module_function

      def trim_dirname(line)
        line.sub(DIR_TRIMMER_PATTERN, '')
      end
    end
  end
end
