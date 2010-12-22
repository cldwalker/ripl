require 'bond'

module Ripl::Completion
  def before_loop
    super
    (config[:completion][:gems] ||= []).concat Ripl.plugins
    Bond.restart config[:completion]
  end
end
Ripl::Shell.include Ripl::Completion
Ripl.config[:completion][:eval_binding] = lambda { Ripl.shell.binding }
