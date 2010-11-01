require 'ripl/shell'
require 'ripl/version'

module Ripl
  extend self

  def run
    ripl_options = parse_options(ARGV)
    ARGV[0] ? run_command(ARGV) : start(ripl_options)
  end

  def parse_options(argv)
    ripl_options = {}

    while argv[0] =~ /^-/
      case argv.shift
      when /-I=?(.*)/
        $LOAD_PATH.unshift(*$1.split(":"))
      when /-r=?(.*)/
        require $1
      when '-f'
        ripl_options[:irbrc] = nil
      when '-d'
        $DEBUG = true
      when '-v', '--version'
        puts Ripl::VERSION; exit
      end
    end

    ripl_options
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
