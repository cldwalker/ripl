require File.join(File.dirname(__FILE__), 'test_helper')

describe "Runner" do
  def set_dollar_zero(val)
    $progname = $0
    alias $0 $progname
    $0 = val
  end

  describe ".start" do
    before_all { ARGV.replace [] }
    before { reset_ripl }

    it "loads riplrc" do
      mock_riplrc
      mock_shell
      Ripl.start
    end

    it "doesn't load riplrc" do
      mock_shell
      dont_allow(Runner).load_rc(anything)
      Ripl.start :riplrc => false
    end

    it "sets a shell's variables" do
      mock_riplrc
      mock_shell
      Ripl.start(:name=>'shh')
      Ripl.shell.name.should == 'shh'
    end

    it "passes options to Ripl.config" do
      mock_riplrc
      mock_shell
      Ripl.start(:history=>'~/.mah_history')
      Ripl.config[:history].should == '~/.mah_history'
    end

    it "overrides config set in riplrc" do
      mock_riplrc { Ripl.config[:name] = 'blah' }
      mock_shell
      Ripl.start(:name=>'dude')
      Ripl.shell.name.should == 'dude'
    end

    it "prints warning if argument not parsed" do
      mock_riplrc
      mock_shell
      capture_stderr {
        Ripl.start :argv =>%w{-Idir command}
      }.should =~ /Unused arguments.*command/
    end
  end

  describe ".run" do
    describe "riplrc" do
      before { reset_ripl }

      it "sets config" do
        mock_riplrc { Ripl.config[:blah] = true }
        mock_shell
        Runner.run([])
        Ripl.config[:blah].should == true
      end

      it "rescues and prints SyntaxError" do
        mock(Runner).load(anything) { raise SyntaxError }
        mock_shell
        capture_stderr { Runner.run([]) }.should =~ %r{^ripl: Error while loading .*.riplrc:#{$/}SyntaxError:}
      end

      it "rescues and prints LoadError" do
        mock(Runner).load(anything) { raise LoadError }
        mock_shell
        capture_stderr { Runner.run([]) }.should =~ %r{^ripl: Error while loading .*.riplrc:#{$/}LoadError:}
      end
    end

    describe "with subcommand" do
      def mock_exec(*args)
        mock(Runner).exec('ripl-rails', *args) do
          set_dollar_zero 'ripl-rails'
          ARGV.replace(args)
          Ripl.start
        end
      end

      it "gets invoked with arguments" do
        mock_exec 'blah'
        ripl("rails", 'blah')
      end

      it "has -F global option parsed" do
        mock_exec '-F'
        dont_allow(Runner).load_rc(anything)
        ripl("rails", "-F", :riplrc=>false)
      end

      it "saves arguments passed to it" do
        mock_exec 'blah', '-F'
        ripl("rails", "blah", "-F", :riplrc=>false)
        Ripl::Runner.argv.should == ['blah', '-F']
      end

      it "has global option parsed" do
        mock_exec '-r=blah'
        mock(Runner).require('blah')
        ripl("rails", "-r=blah")
      end

      it "has global option parsed after arguments" do
        mock_exec 'test', '-r=blah'
        mock(Runner).require('blah')
        ripl("rails", "test", "-r=blah")
      end

      it "has automatic --help" do
        mock_exec '--help'
        mock(Runner).exit
        ripl("rails", "--help").chomp.should == "ripl rails [ARGS] [OPTIONS]"
      end

      it "that is invalid aborts" do
        mock(Runner).abort("`zzz' is not a ripl command.")
        ripl 'zzz', 'arg', :riplrc => false, :loop => false
      end
      after_all { set_dollar_zero 'ripl' }
    end

    describe "with -I option" do
      before { @old_load_path = $:.dup }
      after { $:.replace @old_load_path }

      it "and equal sign adds to $LOAD_PATH" do
        ripl("-I=blah")
        $:[0].should == 'blah'
      end

      it "and no equal sign adds to $LOAD_PATH" do
        ripl("-Ispec")
        $:[0].should == 'spec'
      end

      it "and whitespace delimited argument adds to $LOAD_PATH" do
        ripl("-I", "spec")
        $:[0].should == 'spec'
      end

      it "containing multiple paths adds to $LOAD_PATH" do
        ripl("-I=app:lib")
        $:[0,2].should == ['app', 'lib']
      end

      it "called more than once adds to $LOAD_PATH" do
        ripl("-Ilib", "-Ispec")
        $:[0,2].should == ['spec', 'lib']
      end

      it "with invalid argument doesn't add to $LOAD_PATH" do
        previous_size = $:.size
        ripl("-I")
        $:.size.should == previous_size
      end
    end

    describe "with -r option" do
      it "and equal sign requires path" do
        mock(Runner).require('rip')
        ripl("-r=rip")
      end

      it "and no equal sign requires path" do
        mock(Runner).require('rip')
        ripl("-rrip")
      end

      it "and whitespace delimited argument requires path" do
        mock(Runner).require('rip')
        ripl("-r", "rip")
      end

      it "called more than once requires paths" do
        mock(Runner).require('rip')
        mock(Runner).require('dude')
        ripl("-rrip", "-rdude")
      end

      it "with invalid argument requires blank" do
        mock(Runner).require('')
        ripl('-r')
      end
    end

    it "with -f option doesn't load irbrc" do
      reset_ripl
      reset_config
      mock_shell { |shell|
        mock(shell).loop_once { throw :ripl_exit }
        dont_allow(Runner).load_rc(anything)
      }
      ripl("-f", :loop => false)
      Ripl.config[:irbrc] = '~/.irbrc'
    end

    it "with -F option doesn't load riplrc" do
      reset_ripl
      dont_allow(Runner).load_rc(anything)
      mock_shell { |shell|
        mock(shell).before_loop
        mock(shell).loop_once { throw :ripl_exit }
        mock(shell).after_loop
      }
      ripl("-F", :riplrc => false, :loop => false)
    end

    it "with -d option sets $DEBUG" do
      ripl("-d")
      $DEBUG.should == true
      $DEBUG = nil
    end

    it "with -v option prints version" do
      mock(Runner).exit
      ripl("-v").chomp.should == Ripl::VERSION
    end

    it "with -h option prints help" do
      mock(Runner).exit
      actual = ripl("-h")
      actual.should =~ /^Usage: ripl/
      actual.should =~ /Options:#{$/}  -f/
    end

    it "with invalid options prints errors" do
      capture_stderr {
        ripl('--blah', '-z')
      }.chomp.should == [
        "ripl: invalid option `blah'",
        "ripl: invalid option `z'"
      ].join($/)
    end

    describe "with plugin" do
      before_all do
        Moo = Module.new do
          def parse_option(option, argv)
            option == '--moo' ? puts("MOOOO") : super
          end
        end
        Runner.extend Moo
        Runner.add_options ['--moo', 'just moos']
      end

      it "parses plugin option" do
        ripl("--moo").chomp.should == 'MOOOO'
      end

      it "displays plugin option in --help" do
        mock(Runner).exit
        ripl("--help").should =~ /--moo\s*just moos/
      end

      it "handles invalid option" do
        capture_stderr {
          ripl('--blah')
        }.chomp.should == "ripl: invalid option `blah'"
      end
    end
  end

  describe "subclass" do
    before_all {
      Tuxedo = Class.new(Ripl::Runner)
      Tuxedo.app = 'tuxedo'
      Tuxedo.const_set(:VERSION, '0.0.1')
      set_dollar_zero 'tuxedo'
    }

    it "with -v option prints version" do
      mock(Tuxedo).exit
      mock(Tuxedo).load_rc(Ripl.config[:riplrc])
      mock(Ripl.shell).loop
      capture_stdout {
        Tuxedo.run(['-v'])
      }.chomp.should == Tuxedo::VERSION
    end
    after_all { set_dollar_zero 'ripl' }
  end

  describe "API" do
    Runner::API.instance_methods.each do |meth|
      it "##{meth} is accessible to plugins" do
        mod = Object.const_set "Ping_#{meth}", Module.new
        mod.send(:define_method, meth) {|*args| "pong_#{meth}" }
        runner = Runner.dup
        runner.extend mod
        runner.send(meth).should == "pong_#{meth}"
      end
    end

    it "Runner::MESSAGES only calls #[]" do
      str = File.read(File.dirname(__FILE__)+'/../lib/ripl/runner.rb')
      str.scan(/MESSAGES\S+/).all? {|e| e[/MESSAGES\[/] }.should == true
    end

    it "Runner::OPTIONS only calls #[] and values" do
      str = File.read(File.dirname(__FILE__)+'/../lib/ripl/runner.rb')
      str.scan(/OPTIONS[^_\] ]\S+/).all? {|e| e[/OPTIONS(\[|\.values)/] }.should == true
    end
    after_all { Runner.extend Runner::API }
  end
end
