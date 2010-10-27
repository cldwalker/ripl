require 'ripl/shell'

module Ripl
  extend self

  def start(options={})
    shell(options).loop
  end

  def shell(options={})
    @shell ||= begin
      require 'ripl/readline_shell'
      ReadlineShell.new(options)
    rescue LoadError
      Shell.new(options)
    end
  end
end
