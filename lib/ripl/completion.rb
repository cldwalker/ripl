module Ripl
  module Completion
    def start_completion
      require 'bond'
      Bond.start
      true
    rescue LoadError
      false
    end
  end
end
