module Ripl::Readline
  def get_input
    Readline.readline prompt, true
  end

  def before_loop() @history = Readline::HISTORY; super end
end
Ripl::Shell.include Ripl::Readline
