class Cartage
  # Cartage::Plugin is the basis of the Cartage plugin system. All plug-ins
  # must inherit from this class.
  class Plugin
    class << self
      # Register a subclass.
      def inherited(klass) #:nodoc:
        registered << klass
      end

      # The plugins registered with Cartage.
      def registered
        @registered ||= []
      end

      # A utility method that will find all Cartage plugins and load them. A
      # Cartage plugin is found with 'cartage/*.rb' and descends from
      # Cartage::Plugin.
      def load #:nodoc:
        @found ||= {}
        @loaded ||= {}
        @files ||= Gem.find_files('cartage/*.rb')

        @files.reverse.each do |path|
          name = File.basename(path, '.rb').to_sym
          @found[name] = path
        end

        :repeat while @found.map { |name, plugin|
          load_plugin(name, plugin)
        }.any?
      end

      # Decorate the provided class with lazy initialization methods.
      def decorate(klass) #:nodoc:
        registered.each do |plugin|
          name = plugin.name.split(/::/).last.gsub(/([A-Z])/, '_\1').downcase.
            sub(/^_/, '')
          ivar = "@#{name}"

          klass.send(:define_method, name) do
            instance = instance_variable_defined?(ivar) &&
              instance_variable_get(ivar)

            instance ||= instance_variable_set(ivar, plugin.new(self))
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

    # These are the command classes provided to the cartage binary. Despite the
    # name being plural, the return can either be a single CmdParse::Command
    # class, or an array of CmdParse::Command class. These command classes
    # should inherit from Cartage::Command, since they will be initialized with
    # a cartage parameter.
    def self.commands
      []
    end

    # A plug-in is initialized with the Cartage instance that owns it.
    def initialize(cartage)
      @cartage = cartage
    end

    private
    def resolve_config!(*)
    end
  end
end
