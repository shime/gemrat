require 'spec_helper'
describe Gemrat do
  before do
    test_gemfile = File.new("TestGemfile", "w")
    test_gemfile.write ("https://rubygems.org'\n\n# Specify your gem's dependencies in gemrat.gemspec\ngem 'rspec', '2.13.0'\n")
    test_gemfile.close


    class Gemrat::Gem
      def stubbed_response
        File.read("./spec/resources/rubygems_response_shim_for_#{name}")
      rescue Errno::ENOENT
        ""
      end
      alias_method :fetch_all, :stubbed_response
    end
  end

  after :each do
    Gemrat::Runner.instance = nil
  end

  def capture_stdout(&block)
    original_stdout = $stdout
    $stdout = fake = StringIO.new
    begin
      yield
    ensure
      $stdout = original_stdout
    end
    fake.string
  end

  after do
    File.delete("TestGemfile")
  end

  describe Gemrat::Runner do
    subject { Gemrat::Runner }
    describe "#run" do
      context "when valid arguments are given" do
        context "for one gem" do
          it "adds lastest gem version to gemfile" do
            output  = capture_stdout { subject.run("sinatra", "-g", "TestGemfile") }
            output.should include("'sinatra', '1.4.3' added to your Gemfile")
            gemfile_contents = File.open('TestGemfile', 'r').read
            gemfile_contents.should include("\ngem 'sinatra', '1.4.3'")
            output.should include("Bundling")
          end
        end

        context "for multiple gems" do
          it "adds latest gem versions to gemfile" do
            output  = capture_stdout { subject.run("sinatra", "rails", "minitest", "-g", "TestGemfile") }
            output.should include("'sinatra', '1.4.3' added to your Gemfile")
            output.should include("'minitest', '5.0.5' added to your Gemfile")
            output.should include("'rails', '3.2.13' added to your Gemfile")
            gemfile_contents = File.open('TestGemfile', 'r').read
            gemfile_contents.should include("\ngem 'sinatra', '1.4.3'")
            gemfile_contents.should include("\ngem 'minitest', '5.0.5'")
            gemfile_contents.should include("\ngem 'rails', '3.2.13'")
            output.should include("Bundling")
          end

          context "when one of the gems is invalid" do
            it "adds other gems and runs bundle" do
              output  = capture_stdout { subject.run("sinatra", "beer_maker_2000", "minitest", "-g", "TestGemfile") }
              output.should include("'sinatra', '1.4.3' added to your Gemfile")
              output.should include("'minitest', '5.0.5' added to your Gemfile")
              output.should include("#{Gemrat::Messages::GEM_NOT_FOUND % "beer_maker_2000"}")
              output.should include("Bundling")
            end
          end
        end
      end

      ["when gem name is left out from the arguments", "",
       "when -h or --help is given in the arguments", "-h"].each_slice(2) do |ctx, arg|
        context ctx do
          it "prints usage" do
            output = capture_stdout { subject.run(arg == "" ? nil : arg) }
            output.should include(Gemrat::Messages::USAGE)
          end
        end
      end

      context "when gem is not found" do
        before do
          subject.stub(:gem) do
            gem = Gem.new
            gem.invalid!
          end
          @gem_name = "unexistent_gem"
        end

        it "prints a nice error message" do
          output = capture_stdout { subject.run(@gem_name) }
          output.should include("#{Gemrat::Messages::GEM_NOT_FOUND % @gem_name}")
          output.should_not include("Bundling...")
        end
      end

      context "when gem already exists in a Gemfile" do

        context "when the gem is the newest version" do
          before do
            test_gemfile = File.open("TestGemfile", "w")
            test_gemfile << %Q{https://rubygems.org'
                               # Specify your gem's dependencies in gemrat.gemspec
                               gem 'minitest', '5.0.5'}
            test_gemfile.close
          end
          it "should exit and report failure" do
            output = capture_stdout { subject.run("minitest", "-g", "TestGemfile")}
            output.should include("gem 'minitest' already exists")
            output.should_not include("Bundling...")
          end
        end

        context "when there is a newer gem" do
          before do
            test_gemfile = File.open("TestGemfile", "w")
            test_gemfile << %Q{https://rubygems.org'
                               # Specify your gem's dependencies in gemrat.gemspec
                               gem 'minitest', '5.0.4'}
            test_gemfile.close
          end

          context "when the update is rejected" do
            before do
              Gemrat::Gemfile.any_instance.stub(:input) { "no\n" }
            end

            it "should ask if you want to add the newer gem" do
              output = capture_stdout { subject.run("minitest", "-g", "TestGemfile")}
              output.should include("there is a newer version of the gem")
              output.should_not include("Bundling...")
            end
          end

          context "when the update is approved" do
            before do
              Gemrat::Gemfile.any_instance.stub(:input) { "y\n" }
            end

            it "should ask if you want to add the newer gem" do
              output = capture_stdout { subject.run("minitest", "-g", "TestGemfile")}
              output.should include("there is a newer version of the gem")
              output.should include("gem 'minitest', '5.0.5' added to your Gemfile")
              output.should include("Bundling...")
            end
          end
        end
      end
    end
  end
end
