require 'ripl/shell'

module Ripl
  extend self

  def start(options={})
    shell(options).loop
  end

  def shell(options={})
    @shell ||= Shell.new(options)
  end
end
