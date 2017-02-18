# frozen_string_literal: true

##
# Call +extend+ Cartage::CLI to add the commands defined in the block.
Cartage::CLI.extend do
  # Use +desc+ to write a description about the next command.
  desc 'Show information about Cartage itself'

  # Use +long_desc+ to write a long description about the next command that can
  # be included in a generated RDoc file.
  long_desc <<-'DESC'
Shows various bits of information about Cartage based on the running instance.
Some plug-ins do run-time resolution of configuration values, so what is shown
through these subcommands will not represent that resolution.
  DESC

  # Declare a new command with +command+ and one or more names for the command.
  # This command is available as both <tt>cartage info</tt> and <tt>cartage
  # i</tt>. The block contains the definition of the switches, flags,
  # subcommands, and actions for this command.
  command %w(info i) do |info|
    # Use this extension method to hide this command. GLI 2.13 does not support
    # hiding subcommands.
    info.hide!

    # The same GLI::DSL works on the command being created, Here, we are
    # creating <tt>cartage info plugins</tt>.
    info.desc 'Show the plug-ins that have been found.'
    info.long_desc <<-'DESC'
Only plug-ins using the class plug-in protocol are found this way. Plug-ins
that just provide commands are not reported as plugins.
    DESC
    info.command 'plugins' do |plugins|
      # Implement the #action as a block. It accepts three parameters: the
      # global options hash, the local command options hash, and any arguments
      # passed on the command-line.
      #
      # Within a command's action, a +cartage+ object is available that
      # represents the Cartage instance that will be used for packaging.
      plugins.action do |_global, _options, _args|
        plugs = cartage.plugins.enabled
        if plugs.empty?
          puts 'No active plug-ins.'
        else
          plugs.map! do |plug|
            "* #{plug.plugin_name} (#{plug.version})"
          end
          puts <<-plugins
Active Plug-ins:

#{plugs.sort.join("\n")}
          plugins
        end
      end
    end
  end
end
