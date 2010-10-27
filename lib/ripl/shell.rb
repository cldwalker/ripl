module Ripl
  class Shell
    OPTIONS = {:name=>'ripl', :line=>1, :result_prompt=>'=> ', :prompt=>'>> ',
      :binding=>TOPLEVEL_BINDING, :irbrc=>'~/.irbrc'}

    attr_accessor :line, :binding, :result_prompt
    attr_reader :has_autocompletion
    def initialize(options={})
      @options = OPTIONS.merge options
      @name, @binding, @line = @options.values_at(:name, :binding, :line)
      start_completion
      load_rc
    end

    def start_completion
      require 'bond'
      Bond.start
      @has_autocompletion = true
    rescue LoadError
      @has_autocompletion = false
    end

    def load_rc
      load @options[:irbrc] if File.exists?(File.expand_path(@options[:irbrc]))
    end

    def eval_line(str)
      eval(str, @binding, "(#{@name})", @line)
    end

    def print_eval_error(e)
      warn "#{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
    end

    def format_result(result)
      @options[:result_prompt] + result.inspect
    end

    def loop
      while true do
        input = get_input
        break if input == 'exit'
        puts loop_once(input)
      end
    end

    def get_input
      print @options[:prompt]
      $stdin.gets.chomp
    end

    def loop_once(input)
      begin
        result = eval_line(input)
      rescue Exception => e
        print_eval_error(e)
      end

      eval("_ = #{result.inspect}", @binding) rescue nil
      @line += 1
      format_result result
    end
  end
end
