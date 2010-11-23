module Ripl::History
  def history_file
    @history_file ||= File.expand_path(config[:history])
  end

  def history; @history; end

  def get_input
    (@history << super)[-1]
  end

  def before_loop
    @history = []
    super
    Kernel.at_exit { write_history }
    File.exists?(history_file) &&
      IO.readlines(history_file).each {|e| history << e.chomp }
  end

  def write_history
    File.open(history_file, 'w') {|f| f.write Array(history).join("\n") }
  end
end
Ripl::Shell.send :include, Ripl::History
Ripl.config[:history] = '~/.irb_history'
