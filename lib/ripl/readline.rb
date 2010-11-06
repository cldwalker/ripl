require 'readline'

module Ripl::Readline

  def get_input
    Readline.readline @options[:prompt], true
  end

  def history_file
    @history_file ||= File.expand_path(@options[:history])
  end

  def before_loop
    super
    at_exit { write_history }
    File.exists?(history_file) &&
      IO.readlines(history_file).each {|e| Readline::HISTORY << e.chomp }
  end

  def write_history
    File.open(history_file, 'w') {|f| f.write Readline::HISTORY.to_a.join("\n") }
  end
end
Ripl::Shell.send :include, Ripl::Readline
