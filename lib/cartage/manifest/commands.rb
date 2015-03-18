class Cartage
  class Manifest
    # This module provides a command the ability to properly handle the
    # Cartage::Manifest::MissingError.
    module HandleMissingManifest #:nodoc:
      def handle_missing_manifest
        yield
      rescue Cartage::Manifest::MissingError => e
        $stderr.puts e.message
        command = super_command.commands['manifest'].usage.
          gsub(/^\s*Usage:\s+/,  '    ')
        $stderr.puts command
        false
      end
    end

    # Implement <tt>cartage manifest</tt> to generate Manifest.txt.
    class ManifestCommand < Cartage::Command #:nodoc:
      def initialize(cartage)
        super(cartage, 'manifest')
        takes_commands(false)
        short_desc('Update the Cartage Manifest.txt file.')

        @manifest = cartage.manifest
      end

      def perform(*)
        @manifest.generate
      end
    end

    # Implement <tt>cartage check</tt> to compare the repository against
    # Manifest.txt.
    class CheckCommand < Cartage::Command #:nodoc:
      include HandleMissingManifest

      def initialize(cartage)
        super(cartage, 'check')
        takes_commands(false)
        short_desc('Check the Manifest.txt against the current repository.')

        @manifest = cartage.manifest
      end

      def perform(*)
        handle_missing_manifest do
          @manifest.check
          raise Cartage::QuietError.new($?.exitstatus) unless $?.success?
        end
      end
    end

    class InstallDefaultIgnoreCommand < Cartage::Command #:nodoc:
      def initialize(cartage)
        super(cartage, 'install-ignore')
        takes_commands(false)
        short_desc('Installs the default ignore file.')

        self.options do |opts|
          opts.on('-f', '--force', 'Force write .cartignore.') {
            @mode = :force
          }
          opts.on('-m', '--merge', 'Merge .cartignore with the default.') {
            @mode = :merge
          }
        end

        @manifest = cartage.manifest
        @mode = nil
      end

      def perform(*)
        @manifest.install_default_ignore(mode: @mode)
      end
    end

    class ShowCommand < Cartage::Command #:nodoc:
      include HandleMissingManifest

      def initialize(cartage)
        super(cartage, 'show')
        takes_commands(false)
        short_desc('Show the files that will be included in the package.')

        @manifest = cartage.manifest
      end

      def perform(*)
        handle_missing_manifest do
          @manifest.resolve do |tmpfile|
            puts Pathname(tmpfile).read
          end
        end
      end
    end

    def self.commands #:nodoc:
      [
        ManifestCommand,
        CheckCommand,
        InstallDefaultIgnoreCommand,
        ShowCommand
      ]
    end
  end
end
