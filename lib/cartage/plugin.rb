# frozen_string_literal: true

class Cartage
  # Cartage::Plugin is the basis of the Cartage plug-in system that extends
  # core functionality. All plug-ins of this sort must inherit from this class.
  # (Command extensions are handled by extending Cartage::CLI.)
  class Plugin
    class << self
      # Register a plugin.
      def inherited(plugin) #:nodoc:
        registered[plugin.plugin_name] = plugin
      end

      # The plugins registered with Cartage as a dictionary of plug-in name
      # (the key used for plug-in configuration) and plug-in class.
      def registered
        @registered ||= {}
      end

      # The name of the plugin.
      def plugin_name
        @name ||= name.split(/::/).last.gsub(/([A-Z])/, '_\1').downcase.
          sub(/^_/, '')
      end

      # Iterate the plugins by +name+.
      def each # :yields: name
        registered.each_key { |k| yield k }
      end

      # The version of the plug-in.
      def version
        if const_defined?(:VERSION, false)
          VERSION
        else
          Cartage::VERSION
        end
      end

      # A utility method to load and decorate an object with Cartage plug-ins.
      def load_for(klass) #:nodoc:
        load
        decorate(klass)
      end

      # A utility method that will find all Cartage plug-ins and load them. A
      # Cartage plug-in is found in the Gems as <tt>cartage/plugins/*.rb</tt>
      # and descends from Cartage::Plugin.
      def load #:nodoc:
        @found ||= {}
        @loaded ||= {}
        @files ||= Gem.find_files('cartage/plugins/*.rb')

        @files.reverse_each do |path|
          name = File.basename(path, '.rb').to_sym
          @found[name] = path
        end

        :repeat while @found.map { |name, plugin|
          load_plugin(name, plugin)
        }.any?
      end

      # Decorate the provided class with lazy initialization methods.
      def decorate(klass) #:nodoc:
        registered.each do |name, plugin|
          ivar = "@#{name}"

          klass.send(:undef_method, name) if klass.method_defined?(name)
          klass.send(:define_method, name) do
            instance = instance_variable_defined?(ivar) &&
              instance_variable_get(ivar)

            instance || instance_variable_set(ivar, plugin.new(self))
          end
        end
      end

      private

      def load_plugin(name, plugin)
        return if @loaded[name]

        warn "loading #{plugin}" if $DEBUG
        @loaded[name] = require plugin
      rescue LoadError => e
        warn "error loading #{plugin.inspect}: #{e.message}. Skipping..."
      end
    end

    # Returns +true+ if the feature identified by +name+ is offered by this
    # plug-in. Requires that subclasses implement the #offer_feature? private
    # method.
    def offer?(name)
      enabled? && offer_feature?(name.to_sym)
    end

    # Returns +true+ if the plug-in has been explicitly disabled in
    # configuration.
    def disabled?
      !!@disabled
    end

    # Returns +true+ if the plug-in is enabled (it has not been explicitly
    # disabled).
    def enabled?
      !disabled?
    end

    # The name of this plug-in.
    def plugin_name
      self.class.plugin_name
    end

    # The version of this plug-in
    def version
      self.class.version
    end

    # A plug-in is given, as +cartage+, the instance of Cartage that owns it.
    def initialize(cartage)
      fail NotImplementedError, 'not a subclass' if instance_of?(Cartage::Plugin)
      @cartage = cartage
      @disabled = false
    end

    private

    # The instance of Cartage that owns this plug-in instance.
    attr_reader :cartage # :doc:

    # This method should not be overridden by implementors.
    def resolve_config!(config)
      @disabled = config.disabled
      resolve_plugin_config!(config)
    end

    # Plug-ins that have configuration that needs resolution before use should
    # implement this method. It is provided +config+, which is just the subset
    # of the overall Cartage::Config object that applies to this plug-in.
    def resolve_plugin_config!(config) # :doc:
    end

    # This is an extension point for plug-ins to indicate that they offer the
    # feature with the given +name+. The default implementation should be
    # sufficient for most plug-ins, because it matches the way that plug-in
    # methods are called.
    def offer_feature?(name) # :doc:
      respond_to?(name)
    end
  end

  # A collection of Cartage::Plugin held by a Cartage instance.
  class Plugins
    def initialize # :nodoc:
      @plugins = []
    end

    # Adds one or more +plugins+ to the collection.
    def add(*plugins)
      @plugins.push(*plugins)
    end

    # Return enabled plug-ins.
    def enabled
      @plugins.select(&:enabled?)
    end

    # Map +method+ over all plug-ins offering +feature+. Used to collect data
    # from plug-ins that offer this +feature+.
    def request_map(feature, method = feature)
      feature = feature.to_sym
      method = method.to_sym
      offering(feature).map(&method)
    end

    # Run +method+ on plug-ins offering +feature+. Used to run code in plug-ins
    # that offer this +feature+.
    def request(feature, method = feature)
      feature = feature.to_sym
      method = method.to_sym
      offering(feature).each(&method)
    end

    private

    def offering(name)
      name = name.to_sym
      @plugins.select { |plugin| plugin.offer?(name) }
    end
  end
end
