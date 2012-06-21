class Ripl::Shell
  def self.create(options={})
    if options[:readline]
      require options[:readline] == true ? 'readline' : options[:readline]
      require 'ripl/readline'
    end
    require 'ripl/completion' if options[:completion]
    new(options)
  rescue LoadError
    new(options)
  end

  class << self; public :include; end

  OPTIONS = {
    :name => 'ripl',
    :result_prompt => '=> ',
    :prompt => '>> ',
    :binding => TOPLEVEL_BINDING,
    :irbrc=>'~/.irbrc'
  }
  EXIT_WORDS = [nil, 'exit', 'quit']

  attr_accessor :line, :binding, :result, :name, :input
  def initialize(options={})
    options = OPTIONS.merge options
    @name, @binding = options.values_at(:name, :binding)
    @prompt, @result_prompt = options.values_at(:prompt, :result_prompt)
    @irbrc, @line = options[:irbrc], 1
  end

  # Loops shell until user exits
  def loop
    before_loop
    in_loop
    after_loop
  end

  def config() Ripl.config end

  module API
    MESSAGES = {
      'prompt' => 'Error while creating prompt',
      'print_result' => 'Error while printing result'
    }

    attr_accessor :prompt, :result_prompt
    # Sets up shell before looping by loading ~/.irbrc. Can be extended to
    # initialize plugins and their instance variables.
    def before_loop
      Ripl::Runner.load_rc(@irbrc) if @irbrc
      add_commands(eval("self", @binding))
    end

    def in_loop
      catch(:ripl_exit) { loop_once while(true) }
    end

    def add_commands(obj)
      ![Symbol, Fixnum].include?(obj.class) ? obj.extend(Ripl::Commands) :
        obj.class.send(:include, Ripl::Commands)
    end

    # Runs through one loop iteration: gets input, evals and prints result
    def loop_once
      @error_raised = nil
      @input = get_input
      throw(:ripl_exit) if EXIT_WORDS.include?(@input)
      eval_input(@input)
      print_result(@result)
    rescue Interrupt
      handle_interrupt
    end

    # Handles interrupt (Control-C) by printing a newline
    def handle_interrupt() puts end

    # Sets @result to result of evaling input and print unexpected errors
    def eval_input(input)
      @result = loop_eval(input)
      eval("_ = Ripl.shell.result", @binding)
    rescue Exception => e
      @error_raised = true
      print_eval_error(e)
    ensure
      @line += 1
    end

    # When extending this method, ensure your plugin disables readline:
    # Readline.config[:readline] = false.
    # @return [String, nil] Prints #prompt and returns input given by user
    def get_input
      print prompt
      (input = $stdin.gets) ? input.chomp : input
    end

    # @return [String]
    def prompt
      @prompt.respond_to?(:call) ? @prompt.call : @prompt
    rescue StandardError, SyntaxError
      $stderr.puts "ripl: #{MESSAGES['prompt']}:", format_error($!)
      OPTIONS[:prompt]
    end

    # Evals user input using @binding, @name and @line
    def loop_eval(str)
      eval(str, @binding, "(#{@name})", @line)
    end

    # Prints error formatted by #format_error to STDERR. Could be extended to
    # handle certain exceptions.
    # @param [Exception]
    def print_eval_error(err)
      $stderr.puts format_error(err)
    end

    # Prints result using #format_result
    def print_result(result)
      puts(format_result(result)) unless @error_raised
    rescue StandardError, SyntaxError
      $stderr.puts "ripl: #{MESSAGES['print_result']}:", format_error($!)
    end

    # Formats errors raised by eval of user input
    # @param [Exception]
    # @return [String]
    def format_error(err) Ripl::Runner.format_error(err) end

    # @return [String] Formats result using result_prompt
    def format_result(result)
      result_prompt + result.inspect
    end

    # Called after shell finishes looping.
    def after_loop; end
  end
  include API
end
