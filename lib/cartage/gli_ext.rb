# frozen_string_literal: true

require "gli"

##
module Cartage::CLIOptionsSupport # :nodoc:
  # Clears defaults from a flag-set. By default, only clears symbolic defaults
  # (e.g., <tt>:'default-value'</tt>.)
  def clear_defaults_from(opts, flag_set: flags, symbol_defaults_only: true)
    flag_set.each do |name, flag|
      next unless flag.default_value
      next if symbol_defaults_only && !flag.default_value.is_a?(Symbol)
      next unless opts[name] == flag.default_value

      aliases = [name, *flag.aliases].compact
      aliases += aliases.map(&:to_s)
      aliases.each { |aka| opts[aka] = nil }
    end
  end
end

# Work around a bug with the RdocDocumentListener
module RdocDocumentListenerAppFix # :nodoc:
  def initialize(_global_options, _options, _arguments, app)
    super
    @app = app
  end
end

##
class GLI::Commands::RdocDocumentListener # :nodoc:
  prepend RdocDocumentListenerAppFix
end

##
module GLI::App # :nodoc:
  include Cartage::CLIOptionsSupport

  # Indicate the parent GLI application.
  def app
    self
  end
end

##
class GLI::Command # :nodoc:
  include Cartage::CLIOptionsSupport

  # Indicate the parent GLI application.
  def app
    parent.app
  end

  # Mark the provided command as hidden from documentation.
  def hide!
    singleton_class.send(:define_method, :nodoc) { true }
  end

  def plugin_version_command(*plugin_classes)
    desc "Show the plug-in version"
    command "version" do |version|
      version.hide!
      version.action do |_g, _o, _a|
        plugin_classes.each do |plugin_class|
          puts "cartage-#{plugin_class.plugin_name}: #{plugin_class.version}"
        end
      end
    end
  end
end
