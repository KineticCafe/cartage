require 'cartage'
require 'cmdparse'

class Cartage
  # The base Cartage command object. This is used to provide commands with a
  # reference to the Cartage instance (<tt>@cartage</tt>) that is running under
  # the main command-line program.
  #
  #   class Cartage::InfoCommand < Cartage::Command
  #     def initialize(cartage)
  #       super(cartage, 'info')
  #     end
  #
  #     def perform
  #       puts 'info'
  #     end
  #   end
  #
  # Cartage::Command changes the class-based command protocol from CmdParse so
  # that you must define #perform instead of #execute. This is so that certain
  # common behaviours (such as common config resolution) can be performed for
  # all commands.
  class Command < ::CmdParse::Command
    # Create a ::CmdParse::Command with the given name. Save a reference to the
    # provided cartage object.
    def initialize(cartage, name, takes_commands: false)
      if self.instance_of?(Cartage::Command)
        raise ArgumentError, 'Cartage::Command cannot be instantiated.'
      end

      super(name, takes_commands: takes_commands)

      @cartage = cartage
    end

    # Run the command. Children must *not* implement this method.
    def execute(*args)
      @cartage.send(:resolve_config!, *Array(with_plugins))
      perform(*args)
    end

    ##
    # :method: perform
    #
    # Perform the action of the command. Children *must* implement this method.

    # This optional method is implemented by a plug-in to instruct Cartage to
    # resolve the plug-in configuration for the specified plug-ins. Specify the
    # plug-ins to be resolved as an array of Symbols.
    #
    # Plug-ins resolve by overriding the private method
    # Cartage::Plugin#resolve_config!.
    def with_plugins
      []
    end
  end
end

require_relative 'pack_command'
