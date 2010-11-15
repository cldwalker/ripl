require 'bond'

module Ripl::Completion
  def before_loop
    super
    default = {:eval_binding=>lambda { Ripl.shell.binding }}
    Bond.restart((config[:completion] || {}).merge(default))
  end
end
Ripl::Shell.send :include, Ripl::Completion
