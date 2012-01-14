module Ripl::History
  def history_file
    @history_file ||= File.expand_path(config[:history])
  end

  def history() @history ||= [] end

  def get_input
    (history << super)[-1]
  end

  def read_history
    File.exists?(history_file) && history.empty? &&
      IO.readlines(history_file).each {|e| history << e.chomp }
  end

  def write_history
    File.open(history_file, 'w') {|f| f.write Array(history).join("\n") }
  end
  def before_loop() super; read_history end
  def after_loop() super; write_history end
end
Ripl::Shell.include Ripl::History
Ripl.config[:history] = '~/.irb_history'
