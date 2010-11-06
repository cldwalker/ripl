require 'bond'

module Ripl::Completion
  def before_loop
    Bond.start
    super
  end
end
Ripl::Shell.send :include, Ripl::Completion
