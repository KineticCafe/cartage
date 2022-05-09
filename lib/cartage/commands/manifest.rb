# frozen_string_literal: true

Cartage::CLI.extend do
  desc "Work with the Manifest.txt file"
  long_desc <<~'DESC'
    Commands that manage the Cartage manifest (Manifest.txt) and ignore
    (.cartignore) files for a project.
  DESC
  command "manifest" do |manifest|
    manifest.desc "Check the Manifest.txt file against the current repository"
    manifest.long_desc <<~'DESC'
      Compares the current Cartage manifest against what would be calculated. If
      there is a difference, it will be displayed in unified ('diff -u') format and a
      non-zero exit status will be returned.
      
      The diff output can be suppressed by specifying -q on cartage:
      
          cartage -q manifest check
    DESC
    manifest.command "check" do |check|
      check.action do |_global, _options, _args|
        cartage.manifest.check or
          fail Cartage::CLI::QuietExit, $?.exitstatus
      end
    end

    manifest.desc "Install or update the .cartignore file"
    manifest.long_desc <<~'DESC'
      Creates, replaces, or updates the Cartage ignore file (.cartignore). Will not
      modify an existing .cartignore unless the --mode is overwrite or merge.
    DESC
    manifest.command "cartignore" do |cartignore|
      cartignore.desc "Overwrite or merge an existing .cartignore"
      cartignore.long_desc <<~'DESC'
        Sets the mode for updating the ignore file. When --mode overwrite, the ignore
        file will be replaced with the default ignore file contents. When --mode merge,
        the existing ignore file will be merged with the default ignore file contents.
      DESC
      cartignore.flag :mode, must_match: %w[overwrite merge], arg_name: :MODE

      cartignore.desc "Overwrite an existing .cartignore (--mode overwrite)"
      cartignore.switch %i[f force overwrite], negatable: false

      cartignore.desc "Merge an existing .cartignore (--mode merge)"
      cartignore.switch %i[m merge], negatable: false

      cartignore.action do |_global, options, _args|
        message = if options["merge"] && options["force"]
          "Cannot mix options --force and --merge"
        elsif options["merge"] && options["mode"] == "overwrite"
          "Cannot mix option --merge and --mode overwrite"
        elsif options["force"] && options["mode"] == "merge"
          "Cannot mix option --force and --mode merge"
        end

        if message
          fail Cartage::CLI::CommandException.new(message, cartignore.name_for_help, 64)
        end

        mode = if options["merge"] || options["mode"] == "merge"
          "merge"
        elsif options["force"] || options["mode"] == "overwrite"
          "overwrite"
        end

        cartage.manifest.install_default_ignore(mode: mode)
      end
    end

    manifest.desc "Show the files that will be included in the package"
    manifest.command "show" do |show|
      show.action do |_global, _options, _args|
        cartage.manifest.resolve do |tmpfile|
          puts Pathname(tmpfile).read
        end
      end
    end

    manifest.desc "Generate or update the Manifest.txt file"
    manifest.command %w[generate update] do |generate|
      generate.action do |_global, _options, _args|
        cartage.manifest.generate
      end
    end

    manifest.default_command :check
  end
end
