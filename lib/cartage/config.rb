require 'ostruct'
require 'pathname'

class Cartage
  # The Cartage configuration structure. The supported Cartage-wide
  # configuration fields are:
  #
  # +target+:: The target where the final Cartage package will be created. Sets
  #            Cartage#target. Equivalent to <tt>--target</tt>.
  # +name+:: The name of the package to create. Sets Cartage#name. Equivalent
  #          to <tt>--name</tt>.
  # +root_path+:: The root path of the application. Sets Cartage#root_path.
  #               Equivalent to <tt>--root-path</tt>.
  # +timestamp+:: The timestamp for the final package. Sets Cartage#timestamp.
  #               Equivalent to <tt>--timestamp</tt>.
  # +bundle_cache+:: The bundle cache. Sets Cartage#bundle_cache. Equivalent to
  #                  <tt>--bundle-cache</tt>.
  # +without+:: Groups to exclude from bundle installation. Sets
  #             Cartage#without_groups. Equivalent to <tt>--without</tt>.
  #             This value should be provided as an array.
  # +plugins+:: A dictionary for plug-in configuration groups. See below for
  #             more information.
  #
  # Cartage configuration is not typically partitioned by an environment label,
  # but can be. See the examples below for details.
  #
  # == Plug-Ins
  #
  # Plug-ins also keep configuration in the Cartage configuration structure,
  # but as dictionary (hash) structures under the +plugins+ field. Each plug-in
  # has its own key based on its name, so that the Manifest plug-in (if it had
  # storable configuration values) would keep its configuration in a +manifest+
  # key. See the examples below for details.
  #
  # == Loading Configuration
  #
  # When <tt>--config-file</tt> is specified, the configuration file will be
  # loaded and parsed. If a filename is given, that file will be loaded. If a
  # filename is not given, Cartage will look for the configuration in the
  # following locations:
  #
  # * config/cartage.yml
  # * ./cartage.yml
  # * $HOME/.config/cartage.yml
  # * $HOME/.cartage.yml
  # * /etc/cartage.yml
  #
  # The contents of the configuration file are evaluated through ERB and then
  # parsed from YAML and converted to nested OpenStruct objects. The basic
  # environment example below would look like:
  #
  #   #<OpenStruct development=
  #     #<OpenStruct without=["test", "development", "assets"]>
  #   >
  #
  # == Examples
  #
  # Basic Cartage configuration:
  #
  #   ---
  #   without:
  #     - test
  #     - development
  #     - assets
  #
  # With an environment set:
  #
  #   ---
  #   development:
  #     without:
  #       - test
  #       - development
  #       - assets
  #
  # With the Manifest plug-in (note: the Manifest plug-in does *not* have
  # configurable options; this is for example purposes only).
  #
  #   ---
  #   without:
  #     - test
  #     - development
  #     - assets
  #   manifest:
  #     format: json
  #
  # With the Manifest plug-in and an environment:
  #
  #   ---
  #   development:
  #     without:
  #       - test
  #       - development
  #       - assets
  #     manifest:
  #       format: json
  class Config < OpenStruct
    #:stopdoc:
    DEFAULT_CONFIG_FILES = %w(
    config/cartage.yml
    ./cartage.yml
    ~/.config/cartage.yml
    ~/.cartage.yml
    /etc/cartage.yml
    )
    #:startdoc:

    class << self
      # Load a Cartage configuration file.
      def load(filename)
        config_file = resolve_config_file(filename)
        config = YAML.load(ERB.new(config_file.read, nil, '%<>-').result)
        new(ostructify(config))
      end

      private

      def resolve_config_file(filename)
        return unless filename

        files = if filename == :default
                  DEFAULT_CONFIG_FILES
                else
                  [ filename ]
                end

        file  = files.find { |f| Pathname(f).expand_path.exist? }

        if file
          Pathname(file).expand_path
        else
          message = if filename
                      "Configuration file #{filename} does not exist."
                    else
                      "No default configuration file found."
                    end

          raise ArgumentError, message
        end
      end

      def ostructify(hash)
        hash = hash.dup
        hash.keys.each do |k|
          hash[k.to_sym] = ostructify_recursively(hash.delete(k))
        end
        OpenStruct.new(hash)
      end

      def ostructify_recursively(object)
        case object
        when ::Array
          object.map! { |i| ostructify_recursively(i) }
        when ::OpenStruct
          object = ostructify(object.to_h)
        when ::Hash
          object = ostructify(object)
        end

        object
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

    private
    def hashify(ostruct)
      {}.tap { |hash|
        ostruct.each_pair do |k, v|
          hash[k.to_s] = hashify_recursively(v)
        end
      }
    end

    def hashify_recursively(object)
      case object
      when ::Array
        object.map! { |i| hashify_recursively(i) }
      when ::OpenStruct, ::Hash
        object = hashify(object)
      end

      object
    end
  end
end
