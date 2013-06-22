module Gemrat
  class Arguments

    ATTRIBUTES = [:gem_names, :options]

    ATTRIBUTES.each { |arg| attr_accessor arg }


    def initialize(*args)
      self.arguments = *args
      self.options = OpenStruct.new(parse_options)
      self.gem_names = arguments.take_while { |arg| arg !~ /^-|^--/}
      binding.pry
    end

    private

      attr_accessor :arguments

      def parse_options
        options = {}

        opt_parser = OptionParser.new do |opt|
          opt.banner = "Usage: opt_parser COMMAND [OPTIONS]"
          opt.separator  ""
          opt.separator  "Commands"
          opt.separator  "     start: start server"
          opt.separator  "     stop: stop server"
          opt.separator  "     restart: restart server"
          opt.separator  ""
          opt.separator  "Options"

          opt.on("-g", "--gemfile GEMFILE", "Specify the gemfile to be used") do |gemfile|
            options[:gemfile] = gemfile
          end

          opt.on("--no-version", "Add to gemfile without specifying\
                 the latest gem version.") do
            options[:no_version] = true
          end

          opt.on("--version VERSION", "Specify gem version to be installed") do |version|
            options[:version] = version
          end

          opt.on("-e", "--environment ENVIRONMENTS", Array, "Specify environment(s) in which to place gems") do |env|
            options[:environment] = env
          end

          opt.on("-h","--help","Print this usage") do
            puts opt_parser
          end
        end.parse!

        options
      end
  end
end
