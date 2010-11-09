require 'bond'

module Ripl::Completion
  def before_loop
    Bond.start(config[:completion] || {})
    super
  end
end
Ripl::Shell.send :include, Ripl::Completion
