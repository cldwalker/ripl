require File.join(File.dirname(__FILE__), 'test_helper')

describe "Completion" do
  describe "#before_loop" do
    before_all do
      require 'ripl/completion'
      @shell = Object.new.extend(
        Module.new {
          attr_accessor :config
          def before_loop; end
      }).extend Ripl::Completion
    end

    before { @shell.config = {:completion => {}} }
    after { $".pop }

    it "adds gem plugin to config" do
      $" << '/dir/ripl/some_plugin.rb'
      mock(Bond).restart(:gems =>['ripl/some_plugin.rb'])
      @shell.before_loop
    end

    it "doesn't add local plugin to config" do
      $" << '/dir/ripl/completion.rb'
      mock(Bond).restart(:gems =>[])
      @shell.before_loop
    end
  end
end
