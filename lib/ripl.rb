require 'ripl/shell'
require 'ripl/version'

module Ripl
  extend self

  def run
    ARGV[0] ? run_command(ARGV) : start
  end

  def run_command(argv)
    exec "ripl-#{argv.shift}", *argv
  rescue Errno::ENOENT
    raise unless $!.message =~ /No such file or directory.*ripl-(\w+)/
    abort "`#{$1}' is not a ripl command."
  end

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
