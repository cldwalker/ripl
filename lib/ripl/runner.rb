class Ripl::Runner
  OPTIONS_ARR = %w{-f -F -d -I -r -v -h}
  OPTIONS = {
    '-f' => ['-f', 'Suppress loading ~/.irbrc'],
    '-F' => ['-F', 'Suppress loading ~/.riplrc'],
    '-d' => ['-d, --debug', "Set $DEBUG to true (same as `ruby -d')"],
    '-I' => ['-I PATH', "Add to front of $LOAD_PATH. Delimit multiple paths with ':'"],
    '-r' => ['-r, --require FILE', "Require file (same as `ruby -r')"],
    '-v' => ['-v, --version', 'Print version'],
    '-h' => ['-h, --help', 'Print help']
  }
  MESSAGES = {
    'usage' => 'Usage', 'options' => 'Options', 'args' => 'ARGS',
    'command' => 'COMMAND', 'run_command' => "`%s' is not a %s command.",
    'start' => "Unused arguments", 'load_rc' => 'Error while loading %s',
    'parse_option' => 'invalid option'
  }

  class << self; attr_accessor :argv, :app; end
  self.app = 'ripl'

  # Adds commandline options for --help
  def self.add_options(*options)
    options.each {|e|
      OPTIONS[e[0][/-\w+/]] = e
      OPTIONS_ARR << e[0][/-\w+/]
    }
  end

  def self.run(argv=ARGV)
    argv[0].to_s[/^[^-]/] ? run_command(argv) : start(:argv => argv)
  end

  def self.run_command(argv)
    exec "#{app}-#{cmd = argv.shift}", *argv
  rescue SystemCallError
    raise unless $!.message =~ /No such file or directory.*#{app}-(\w+)/ ||
      $!.message.include?("Invalid argument - execvp(2) failed")
    abort MESSAGES['run_command'] % [cmd, app]
  end

  def self.start(options={})
    @argv = options.delete(:argv) || ARGV
    argv = @argv.dup
    load_rc(Ripl.config[:riplrc]) unless argv.delete('-F') || options[:riplrc] == false
    argv.each {|e| e[/^-/] ? break : argv.shift } if $0[/#{app}-\w+$/]
    parse_options(argv) if $0[/#{app}$|#{app}-\w+$/]
    warn "#{app}: #{MESSAGES['start']}: #{argv.inspect}" if !argv.empty?
    Ripl.shell(options).loop
  end

  def self.load_rc(file)
    load file if File.exists?(File.expand_path(file))
  rescue StandardError, SyntaxError, LoadError
    $stderr.puts "#{app}: #{MESSAGES['load_rc'] % file}:", format_error($!)
  end

  module API
    def parse_options(argv)
      while argv[0] =~ /^-/
        case argv.shift
        when /-I=?(.*)/
          $LOAD_PATH.unshift(*($1.empty? ? argv.shift.to_s : $1).split(":"))
        when /-r=?(.*)/        then require($1.empty? ? argv.shift.to_s : $1)
        when '-d'              then $DEBUG = true
        when '-v', '--version' then puts(Object.const_get(app.capitalize)::VERSION); exit
        when '-f'              then Ripl.config[:irbrc] = false
        when '-h', '--help'    then puts(help); exit
        when /^(--?[^-]+)/     then parse_option($1, argv)
        end
      end
    end

    def help
      return("#{app} #{$1} [ARGS] [OPTIONS]") if $0[/#{app}-(\w+)/]
      name_max = OPTIONS.values.map {|e| e[0].length }.max
      desc_max = OPTIONS.values.map {|e| e[1].length }.max
      m = MESSAGES
      ["%s: #{app} [%s] [%s] [%s]" % ( [m['usage'], m['command'], m['args'],
        m['options'].upcase] ), "#{$/}#{m['options']}:", OPTIONS_ARR.
        map {|e| n,d = OPTIONS[e]; "  %-*s  %-*s" % [name_max, n, desc_max, d] }]
    end

    def parse_option(option, argv)
      warn "#{app}: #{MESSAGES['parse_option']} `#{option.sub(/^-+/, '')}'"
    end

    def format_error(err)
      stack = err.backtrace.take_while {|line| line !~ %r{/ripl/\S+\.rb} }
      "#{err.class}: #{err.message}#{$/}    #{stack.join("#{$/}    ")}"
    end
  end
  extend API
end
