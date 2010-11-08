require 'ripl/shell'
require 'ripl/runner'
require 'ripl/history'
require 'ripl/version'

module Ripl
  def self.config
    @config ||= {:readline=>true, :riplrc=>'~/.riplrc'}
  end

  def self.start(*args); Runner.start(*args); end

  def self.shell(options={})
    @shell ||= Ripl::Shell.create(options)
  end
end
