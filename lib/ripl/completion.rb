require 'bond'

module Ripl::Completion
  def before_loop
    super
    options = {:eval_binding=>lambda { Ripl.shell.binding }}
    Bond.restart((config[:completion] || {}).merge(options))
  end
end
Ripl::Shell.send :include, Ripl::Completion
