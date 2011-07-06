require 'bond'

module Ripl::Completion
  @@completions = []

  #
  # Adds a tab-completion rule.
  #
  # @param [Hash] options
  #   Pattern matching options.
  #
  # @yield [match]
  #   The given block will be passed the matched data, and should return
  #   an Array of possible completions.
  #
  # @yieldparam [String, nil] match
  #   The matched data.
  #
  def self.complete(options,&block)
    @@completions << [options, block]
    return true
  end

  def before_loop
    super
    (config[:completion][:gems] ||= []).concat Ripl.plugins
    Bond.restart config[:completion]

    @@completions.each do |options,block|
      Bond.complete(options,&block)
    end
  end
end
Ripl::Shell.include Ripl::Completion
Ripl.config[:completion][:eval_binding] = lambda { Ripl.shell.binding }
