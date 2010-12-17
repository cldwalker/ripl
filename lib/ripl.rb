module Ripl
  def self.config
    @config ||= {:readline=>true, :riplrc=>'~/.riplrc', :completion=>{}}
  end

  def self.start(*args); Runner.start(*args); end

  def self.shell(options={})
    if options == {} || !@shell
      @shell = Shell.create(config.merge!(options))
    end
    @shell
  end
  module Commands; end
end

require 'ripl/shell'
require 'ripl/runner'
require 'ripl/history'
require 'ripl/version'
