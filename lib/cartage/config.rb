# frozen_string_literal: true

begin
  require "psych"
rescue LoadError
  nil # This has been intentionally suppressed.
end
require "ostruct"
require "pathname"
require "erb"
require "yaml"

class Cartage
  # The Cartage configuration structure. The supported Cartage-wide
  # configuration fields are:
  #
  # +name+:: The name of the application. Sets Cartage#name. Equivalent to
  #          <tt>--name</tt>. Optional, defaults to the basename of the origin
  #          repo URL. Overridden with <tt>cartage --name NAME</tt>.
  # +target+:: The target path for the Cartage package. Optional, defaults to
  #            <tt>./tmp</tt>. Overridden with <tt>cartage --target PATH</tt>.
  # +root_path+:: The root path of the application. Optional, defaults to the
  #               top of the repository (<tt>git rev-parse --show-cdup</tt>).
  #               Overridden with <tt>cartage --root-path ROOT_PATH</tt>.
  # +timestamp+:: Equivalent to <tt>--timestamp</tt>. The timestamp for the
  #               final package (which is
  #               <tt><em>name</em>-<em>timestamp</em></tt>). Optional,
  #               defaults to the current time in UTC. Overridden with
  #               <tt>cartage --timestamp TIMESTAMP</tt>. This value is *not*
  #               validated to be a time value when supplied.
  # +compression+:: The type of compression to be used. Optional, defaults to
  #                 'bzip2'. Must be one of 'bzip2', 'gzip', or 'none'.
  #                 Overridden with <tt>cartage --compression TYPE</tt>.
  #
  #                 This affects the compression and filenames of both the
  #                 final package and the dependency cache.
  # +quiet+:: Silence normal output. Optional, defaults false. Overridden with
  #           <tt>cartage --quiet</tt>.
  # +verbose+:: Show verbose output. Optional, defaults false. Overridden with
  #             <tt>cartage --verbose</tt>.
  # +disable_dependency_cache+:: Disable dependency caching. Optional, defaults
  #                              false.
  # +dependency_cache_path+:: The path where the dependency cache will be
  #                           written (<tt>dependency-cache.tar.*</tt>) for use
  #                           in successive builds. Optional, defaults to
  #                           <tt>./tmp</tt>. Overridden with <tt>cartage
  #                           --dependency-cache-path PATH</tt>.
  #
  #                           On a CI system, this should be written somewhere
  #                           that the CI system uses for build caching.
  #
  # == Commands and Plug-Ins
  #
  # Commands and plug-ins have access to configuration dictinoaries in the main
  # Cartage configuration structure. Command configuration dictionaries are
  # found under +commands+ and plug-in configuration dictionaries are found
  # under +plugins+.
  #
  # +commands+:: This dictionary is for command-specific configuration. The
  #              keys are freeform and should be based on the *primary* name of
  #              the command (so the <tt>cartage pack</tt> command should use
  #              the key <tt>pack</tt>.)
  # +plugins+:: This dictionary is for plug-in-specific configuration. See each
  #             plug-in for configuration options. The keys to the plug-ins are
  #             based on the plug-in name. cartage-bundler is available as
  #             Cartage::Bundler; the transformed plug-in name will be
  #             <tt>bundler</tt>.
  #
  # == Loading Configuration
  #
  # When <tt>--config-file</tt> is specified, the configuration file will be
  # loaded and parsed. If a filename is given, that file will be loaded. If a
  # filename is not given, Cartage will look for the configuration in the
  # following locations:
  #
  # * ./config/cartage.yml
  # * ./.cartage.yml
  # * ./cartage.yml
  #
  # The contents of the configuration file are evaluated through ERB and then
  # parsed from YAML and converted to nested OpenStruct objects.
  class Config < OpenStruct
    # :stopdoc:
    unless defined?(DEFAULT_CONFIG_FILES)
      DEFAULT_CONFIG_FILES = %w[
        ./config/cartage.yml
        ./cartage.yml
        ./.cartage.yml
      ].each(&:freeze).freeze
    end
    # :startdoc:

    class << self
      # Load a Cartage configuration file as specified by +filename+. If
      # +filename+ is the special value <tt>:default</tt>, project-specific
      # configuration files will be located.
      def load(filename)
        config_file = resolve_config_file(filename)
        config = ::YAML.load(ERB.new(config_file.read, trim_mode: "%-").result)
        new(config)
      end

      # Read the contents of +filename+ if and only if it exists. For use in
      # ERB configuration of Cartage to read local or Ansible-created files.
      def import(filename)
        File.read(filename) if File.exist?(filename)
      end

      private

      def resolve_config_file(filename)
        return unless filename

        filename = nil if filename == :default

        files = if filename
          [filename]
        else
          DEFAULT_CONFIG_FILES
        end

        file = files.find { |f| Pathname(f).expand_path.exist? }

        if file
          Pathname(file).expand_path
        elsif filename
          fail ArgumentError, "Configuration file #{filename} does not exist."
        else
          StringIO.new("{}")
        end
      end

      def ostructify(object)
        case object
        when ::Array
          object.map { |e| ostructify(e) }
        when ::OpenStruct, ::Hash
          OpenStruct.new({}.tap { |h|
            object.each_pair { |k, v| h[k] = ostructify(v) }
          })
        else
          object
        end
      end
    end

    # Convert the entire Config structure to a hash recursively.
    def to_h
      hashify(self)
    end

    # Override the default #to_yaml implementation.
    def to_yaml
      to_h.to_yaml
    end

    def initialize(hash = nil) # :nodoc:
      super(hash && self.class.send(:ostructify, hash))
      self.plugins ||= OpenStruct.new
      self.commands ||= OpenStruct.new
    end

    private

    def hashify(object, convert_keys: :to_s)
      case object
      when ::Array
        object.map { |e| hashify(e) }
      when ::OpenStruct, ::Hash
        {}.tap { |h|
          object.each_pair { |k, v|
            k = case convert_keys
            when :to_s
              k.to_s
            when :to_sym
              k.to_sym
            else
              k
            end
            h[k.to_s] = hashify(v)
          }
        }
      else
        object
      end
    end
  end
end
