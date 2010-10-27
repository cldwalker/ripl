require 'readline'

class Ripl::ReadlineShell < Ripl::Shell
  def get_input
    Readline.readline @options[:prompt], true
  end
end
