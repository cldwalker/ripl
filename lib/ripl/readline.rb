require 'readline'
require 'ripl/completion'

module Ripl::Readline
  include Ripl::Completion

  def get_input
    Readline.readline @options[:prompt], true
  end

  def history_file
    @history_file ||= File.expand_path(@options[:history])
  end

  def before_loop
    start_completion
    super
    File.exists?(history_file) &&
      IO.readlines(history_file).each {|e| Readline::HISTORY << e.chomp }
  end

  def after_loop
    File.open(history_file, 'w') {|f| f.write Readline::HISTORY.to_a.join("\n") }
  end
end

Ripl::Shell.send :include, Ripl::Readline
