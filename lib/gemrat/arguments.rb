module Gemrat
  class Arguments

    ATTRIBUTES = [:gem_names, :gemfile, :options]

    ATTRIBUTES.each { |arg| attr_accessor arg }


    def initialize(*args)
      #self.options = OpenStruct.new # Set in place for future OptionParser
      # implementation
      self.arguments = *args

      validate

      parse_options
      #extract_options
    end

    def gem_names
      arguments.take_while { |arg| arg !~ /^-|^--/}
    end

    private

      attr_accessor :arguments

      def validate
        raise ArgumentError if invalid?
      end

      def parse_options
        self.options = OpenStruct.new
        set_defaults

        opt_parser = OptionParser.new do |opt|
          opt.on("-g GEMFILE", "--gemfile GEMFILE", "Specify the gemfile to be used") do |gemfile|
            binding.pry
            self.options.gemfile = gemfile
          end

          opt.on("--no-version", "Add to gemfile without specifying\
                 the latest gem version.") do
            self.options.no_version = true
          end

          opt.on("--version VERSION", "Specify gem version to be installed") do |version|
            self.options.version = version
          end

          opt.on("-e", "--environment x,y", Array, "Specify environment in which to place gems") do |env|
            self.options.environment = env
          end
        end
        opt_parser.parse!
        self.gem_names = ARGV
      end

      def set_defaults
        self.options.no_version = false
        self.options.no_install = false
        self.options.gemfile = "Gemfile"
      end

      def invalid?
        gem_names.empty? || gem_names.first =~ /-h|--help/ || gem_names.first.nil?
      end

      def extract_options
        options  = arguments - gem_names
        opts     = Hash[*options]

        self.gemfile  = opts.delete("-g") || opts.delete("--gemfile") || "Gemfile"
      rescue ArgumentError
        # unable to extract options, leave them nil
      end
  end
end
