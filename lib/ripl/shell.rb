module Ripl
  class Shell
    OPTIONS = {:name=>'ripl', :line=>1, :result_prompt=>'=> ', :prompt=>'>> ',
      :binding=>TOPLEVEL_BINDING, :irbrc=>'~/.irbrc'}

    attr_accessor :line, :binding, :result_prompt, :last_result
    def initialize(options={})
      @options = OPTIONS.merge options
      @name, @binding, @line = @options.values_at(:name, :binding, :line)
      @irbrc = @options[:irbrc]
    end

    def loop
      before_loop
      during_loop
      after_loop
    end

    def config; Ripl.config; end
  end

  module Hooks
    def before_loop
      load @irbrc if @irbrc && File.exists?(File.expand_path(@irbrc))
    rescue StandardError, SyntaxError
      warn "Error while loading #{@irbrc}:\n"+ format_error($!)
    end

    def during_loop
      while true do
        @error_raised = nil
        input = get_input
        break if !input || input == 'exit'
        loop_once(input)
        puts(format_result(@last_result)) unless @error_raised
      end
    end

    def get_input
      print @options[:prompt]
      $stdin.gets.chomp
    end

    def loop_once(input)
      @last_result = loop_eval(input)
      eval("_ = Ripl.shell.last_result", @binding)
    rescue Exception => e
      @error_raised = true
      print_eval_error(e)
    ensure
      @line += 1
    end

    def loop_eval(str)
      eval(str, @binding, "(#{@name})", @line)
    end

    def print_eval_error(e)
      warn format_error(e)
    end

    def format_error(e)
      "#{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
    end

    def format_result(result)
      @options[:result_prompt] + result.inspect
    end

    def after_loop; end
  end
  Shell.send :include, Hooks
end
