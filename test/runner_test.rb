require File.join(File.dirname(__FILE__), 'test_helper')

describe "Runner" do
  describe ".start" do
    before { reset_ripl }

    it "loads riplrc" do
      mock_riplrc
      mock_shell
      Ripl.start
    end

    it "sets a shell's variables" do
      mock_riplrc
      mock_shell
      Ripl.start(:name=>'shh')
      Ripl.shell.name.should == 'shh'
    end

    it "overrides config set in riplrc" do
      mock_riplrc { Ripl.config[:name] = 'blah' }
      mock_shell
      Ripl.start(:name=>'dude')
      Ripl.shell.name.should == 'dude'
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

      it "catches and prints error" do
        mock(Runner).load(anything) { raise SyntaxError }
        mock_shell
        capture_stderr { Runner.run([]) }.should =~ %r{^ripl: Error while loading ~/.riplrc:\nSyntaxError:}
      end
    end

    describe "with subcommand" do
      it "that is valid gets invoked with arguments" do
        mock(Runner).exec('ripl-rails', 'blah') { Ripl.start }
        ripl("rails", 'blah')
      end

      it "has global option parsed" do
        mock(Runner).exec('ripl-rails', '-F') { Ripl.start :argv => ['-F'] }
        dont_allow(Runner).load_rc(anything)
        ripl("rails", "-F", :riplrc=>false)
      end

      it "that is invalid aborts" do
        mock(Runner).abort("`zzz' is not a ripl command.")
        ripl 'zzz', :riplrc => false, :loop => false
      end
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
      stub(Kernel).at_exit()
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
        stub(Kernel).at_exit
        mock(shell).before_loop
        mock(shell).loop_once { throw :ripl_exit }
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
      actual.should =~ /Options:\n  -f/
    end

    it "with invalid options prints errors" do
      capture_stderr {
        ripl('--blah', '-z')
      }.chomp.should == "ripl: invalid option `blah'\nripl: invalid option `z'"
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
end
