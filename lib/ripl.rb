module Ripl
  def self.config
    local_riplrc = File.join(Dir.pwd, '.riplrc')
    riplrc = ENV['RIPL_RC'] || (local_riplrc if File.exist?(local_riplrc)) || '~/.riplrc'
    @config ||= {:readline => true, :riplrc => riplrc, :completion => {}}
  end

  def self.start(*args) Runner.start(*args) end
  def self.started?()   instance_variable_defined?(:@shell) end

  def self.plugins
    file =  File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
    $".map {|e| e[/ripl\/[^\/]+$/] }.compact -
      Dir["#{File.dirname(file)}/ripl/*.rb"].map {|e| e[/ripl\/[^\/]+$/] }
  end

  def self.shell(options={})
    @shell ||= Shell.create(config.merge!(options))
  end

  module Commands
    class<<self; public :include; end
  end
end

require 'ripl/shell'
require 'ripl/runner'
require 'ripl/history'
require 'ripl/version'
