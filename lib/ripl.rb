require 'ripl/shell'
require 'ripl/version'

module Ripl
  extend self

  def config
    @config ||= {}
  end

  def run
    parse_options(ARGV)
    ARGV[0] ? run_command(ARGV) : start
  end

  def parse_options(argv)
    while argv[0] =~ /^-/
      case argv.shift
      when /-I=?(.*)/
        $LOAD_PATH.unshift(*$1.split(":"))
      when /-r=?(.*)/
        require $1
      when '-d'
        $DEBUG = true
      when '-v', '--version'
        puts Ripl::VERSION; exit
      when '-f'
        ENV['RIPL_IRBRC'] = 'false'
      end
    end
  end

  def run_command(argv)
    exec "ripl-#{argv.shift}", *argv
  rescue Errno::ENOENT
    raise unless $!.message =~ /No such file or directory.*ripl-(\w+)/
    abort "`#{$1}' is not a ripl command."
  end

  def start(options={})
    config[:irbrc] = ENV['RIPL_IRBRC'] != 'false' if ENV['RIPL_IRBRC']
    shell(options.merge(config)).loop
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
