class Ripl::Shell
  OPTIONS = {:name=>'ripl', :result_prompt=>'=> ', :prompt=>'>> ',
    :binding=>TOPLEVEL_BINDING, :irbrc=>'~/.irbrc'}

  def self.create(options={})
    require 'ripl/readline' if options[:readline]
    require 'ripl/completion'
    new(options)
  rescue LoadError
    new(options)
  end

  attr_accessor :line, :binding, :result_prompt, :result, :name
  attr_writer   :prompt
  def initialize(options={})
    options = OPTIONS.merge options
    @name, @binding = options.values_at(:name, :binding)
    @prompt, @result_prompt = options.values_at(:prompt, :result_prompt)
    @irbrc, @line = options[:irbrc], 1
  end

  # Loops shell until user exits
  def loop
    before_loop
    catch(:ripl_exit) { while(true) do; loop_once; end }
    after_loop
  end

  def config; Ripl.config; end

  # Runs through one loop iteration: gets input, evals and prints result
  def loop_once
    @error_raised = nil
    @input = get_input
    throw(:ripl_exit) if !@input || @input == 'exit'
    eval_input(@input)
    print_result(@result)
  end

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

  module API
    # Sets up shell before looping by loading ~/.irbrc. Can be extended to
    # initialize plugins and their instance variables.
    def before_loop
      Ripl::Runner.load_rc(@irbrc) if @irbrc
      add_commands(loop_eval("self"))
    end

    def add_commands(obj)
      ![Symbol, Fixnum].include?(obj.class) ? obj.extend(Ripl::Commands) :
        obj.class.send(:include, Ripl::Commands)
    end

    # @return [String, nil] Prints #prompt and returns input given by user
    def get_input
      print prompt
      $stdin.gets.chomp
    end

    # @return [String]
    def prompt
      @prompt.respond_to?(:call) ? @prompt.call : @prompt
    end

    # Evals user input using @binding, @name and @line
    def loop_eval(str)
      eval(str, @binding, "(#{@name})", @line)
    end

    # Prints error formatted by #format_error to STDERR. Could be extended to
    # handle certain exceptions.
    # @param [Exception]
    def print_eval_error(err)
      warn format_error(err)
    end

    # Prints result using #format_result
    def print_result(result)
      puts(format_result(result)) unless @error_raised
    end

    # Formats errors raised by eval of user input
    # @param [Exception]
    # @return [String]
    def format_error(err); Ripl::Runner.format_error(err); end

    # @return [String] Formats result using result_prompt
    def format_result(result)
      @result_prompt + result.inspect
    end

    # Called after shell finishes looping.
    def after_loop; end
  end
  include API
end
