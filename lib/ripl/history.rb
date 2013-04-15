module Ripl::History
  HISTORY_FILE = '~/.irb_history'

  def history_file
    @history_file ||= config[:history] && File.expand_path(config[:history])
  end

  def history() @history ||= [] end

  def get_input
    (history << super)[-1]
  end

  def read_history
    if ((history_file && File.exists?(history_file)) && history.empty?)
      IO.readlines(history_file).each {|e| history << e.chomp }
    end
  end

  def write_history
    if history_file
      File.open(history_file, 'w') {|f| f.puts(*Array(history)) }
    end
  end
  def before_loop() super; read_history end
  def after_loop() super; write_history end
end
Ripl::Shell.include Ripl::History
Ripl.config[:history] = ENV.fetch('RIPL_HISTORY',Ripl::History::HISTORY_FILE)
