require 'bond'

module Ripl::Completion
  def before_loop
    super
    Bond.restart(config[:completion] || {})
  end
end
Ripl::Shell.send :include, Ripl::Completion
