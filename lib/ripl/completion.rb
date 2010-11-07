require 'bond'

module Ripl::Completion
  def before_loop
    super
    Bond.start(config[:completion] || {}) unless Bond.started?
  end
end
Ripl::Shell.send :include, Ripl::Completion
