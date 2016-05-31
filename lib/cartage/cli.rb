# frozen_string_literal: true

require 'cartage'
require_relative 'gli_ext'

::GLI::Commands::Help.skips_pre = false

##
class Cartage
  # The Cartage command-line application, as a GLI application.
  class CLI
    # Commands that want to return a non-zero exit code without a displayed
    # message should raise Cartage::QuietExit with the exit status.
    class QuietExit < StandardError
      include ::GLI::StandardException

      def initialize(exit_code) #:nodoc:
        @exit_code = exit_code
      end

      # The exit code to be used.
      attr_reader :exit_code
    end

    # A local alias for GLI::CustomExit. Initialize with +message+ and
    # +exit_status+. The message will be displayed, and the exit status will be
    # returned. This should be used for *failure* of the command.
    class CustomExit < ::GLI::CustomExit; end

    # A local alias for GLI::CommandException. This exception is similar to
    # CustomExit, but should be used when there is a configuration issue, or a
    # conflict in flags or switches. It requires three parameters:
    #
    # 1. The message;
    # 2. The command name for help (+command.name_for_help+);
    # 3. The exit status.
    class CommandException < ::GLI::CommandException; end

    Cartage::Plugin.load

    include ::GLI::App #:nodoc:

    class << self
      # When called with a block, this method reopens Cartage::CLI to add new
      # commands. If modules are provided, the normal Object#extend method
      # will be called.
      #
      # +mods+ are the modules to extend onto Cartage::CLI. +block+ is the
      # block that contains CLI command extensions (using the GLI DSL).
      def extend(*mods, &block)
        return super(*mods) unless block_given?
        cli.instance_eval(&block)
      end

      # Run the application. Should only be run from +bin/cartage+. +args+ are
      # the command-line arguments (e.g., +ARGV+) to the CLI.
      def run(*args)
        cli.run(*args)
      end

      private

      def cli
        @cli ||= new
      end

      private :new
    end

    # The Cartage configuration and execution engine for the running instance
    # of the Cartage CLI. The first time that this is used, an explicit
    # +config+ (which must be a Cartage::Config object) may be provided.
    def cartage(config = nil)
      if defined?(@cartage) && @cartage && config
        fail 'Cannot provide another configuration after initialization.'
      end
      @cartage ||= Cartage.new(config)
    end

    attr_writer :backtrace # :nodoc:

    # Indicates whether backtrace printing is turned on.
    def backtrace?
      !!@backtrace
    end
  end

  CLI.extend do
    accept(Cartage::Config) do |value|
      Cartage::Config.load(value)
    end

    program_desc 'Manage releaseable packages'
    program_long_desc <<-'DESC'
Cartage provides a repeatable means to create a package for a server-side
application that can be used in deployment with a configuration tool like
Ansible, Chef, Puppet, or Salt.
    DESC
    version Cartage::VERSION

    subcommand_option_handling :normal
    arguments :strict
    synopsis_format :terminal

    desc 'Silence normal output.'
    switch %i(q quiet)

    desc 'Show verbose output.'
    switch %i(v verbose)

    desc 'Show the backtrace when an error occurs.'
    switch %i(T trace), negatable: false

    desc 'Use the specified Cartage configuration file.'
    long_desc <<-'DESC'
Use the specified configuration file. If not specified, the configuration is
found relative to the current working directory (assumed to be the project
root) at one of the following locations:

1.  config/cartage.yml
2.  cartage.yml
3.  .cartage.yml
    DESC
    flag [ :C, 'config-file' ],
      type: Cartage::Config,
      arg_name: :FILE,
      default_value: :'<project-config>'

    desc 'The name of the package.'
    long_desc <<-'DESC'
The name of the package is used with the timestamp to create the final package
name. Defaults to the last part of the repo URL.
    DESC
    flag %i(n name), arg_name: :NAME, default_value: :'<repo-name>'

    desc 'The destination of the created package.'
    long_desc 'Where the final package will be written.'
    flag %i(t target), arg_name: :PATH, default_value: :tmp

    desc 'The package source root path.'
    long_desc <<-'DESC'
Where the package is built from. Defaults to the root of the repository.
    DESC
    flag [ :r, 'root-path' ], arg_name: :PATH, default_value: :'<repo-root-path>'

    desc 'The timestamp used for building the package.'
    long_desc <<-'DESC'
The timestamp is used with the name of the package is used to create the final
package name.
    DESC
    flag [ :timestamp ], arg_name: :TIMESTAMP

    desc 'Disable the use of vendor dependency caching.'
    switch [ 'disable-dependency-cache' ], negatable: false

    desc 'The path where vendored dependencies will be cached between builds.'
    long_desc <<-'DESC'
Dependencies for deployable packages are vendored. To reduce network calls and
build time, Cartage will cache the vendored dependencies in a tarball
(dependency-cache.tar.bz2) in this path.
    DESC
    flag [ 'dependency-cache-path' ],
      arg_name: :PATH,
      default_value: :'<default-dependency-cache-path>'

    commands_from 'cartage/commands'

    desc 'Save the computed configuration as a configuration file.'
    arg :'CONFIG-FILE'
    command '_save' do |save|
      save.hide!

      save.action do |_global, _options, args|
        name = args.first
        name = "#{name}.yml" unless name == '-' || name.end_with?('.yml')

        Cartage::Config.new(cartage.config).tap do |config|
          config.name ||= cartage.name
          config.root_path ||= cartage.root_path.to_s
          config.target ||= cartage.target.to_s
          config.timestamp ||= cartage.timestamp.to_s
          config.compression ||= cartage.compression.to_s
          config.disable_dependency_cache = cartage.disable_dependency_cache
          config.dependency_cache_path = cartage.dependency_cache_path.to_s
          config.quiet = cartage.quiet || false
          config.verbose = cartage.verbose || false

          if name == '-'
            puts config.to_yaml
          else
            Pathname(name).write(config.to_yaml)
          end
        end
      end
    end

    on_error do |ex|
      unless ex.kind_of?(Cartage::CLI::QuietExit)
        output_error_message(ex)
        ex.backtrace.each { |l| puts l } if backtrace?
      end
    end

    pre do |global, _command, _options, _args|
      self.backtrace = global[:trace]

      clear_defaults_from(global)

      config = case global['config-file']
               when Cartage::Config
                 global['config-file']
               when nil
                 Cartage::Config.load(:default)
               else
                 fail 'Invalid config-file'
               end

      # Configure Cartage from the config file and global switches.
      config.disable_dependency_cache ||= global['disable-dependency-cache']
      config.quiet ||= global['quiet']
      config.verbose ||= global['verbose']

      config.name = global['name'] if global['name']
      config.target = global['target'] if global['target']
      config.root_path = global['root-path'] if global['root-path']
      config.timestamp = global['timestamp'] if global['timestamp']
      if global['dependency-cache-path']
        config.dependency_cache_path = global['dependency-cache-path']
      end

      cartage(config)
    end
  end
end
