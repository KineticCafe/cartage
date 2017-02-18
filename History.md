### 2.1 / 2017-02-18

*   Cartage 2.1 now knows how to load plug-ins relative to the project root
    path. If you have a plug-in that you aren’t ready to release as a gem, just
    put it in your project as `<ROOT_PATH>/lib/cartage/plugins/foo.rb`; Cartage
    will find it automatically. This feature does not work with command
    extensions.

*   The hidden command, `cartage info plugins`, will now correctly report
    plug-in versions.

*   Cartage tries to restore files that were modified by a build system prior
    to packaging. This would fail on files that were not part of the resulting
    tarball (because they were in .cartignore). This has been fixed.

*   A new utility function, Cartage#recursive_copy has been added to
    recursively copy directories from disk into the work path. The interaction
    of relative and absolute directories is subtle but documented on the method
    itself.

### 2.0 / 2016-05-31

*   Rewrite! Over the last year, a number of deficiencies have been found,
    especially related to the extensibility and the execution of various
    phases. Cartage 2.0 is a rewrite of major parts of the system and is
    intentionally not backwards compatible with Cartage 1.0. Documentation for
    upgrading is provided.

    *   Changed from CmdParse to GLI for providing CLI interface structure.

    *   Removed the -E/--environment flag and support for environment-tagged
        configuration.

    *   Added compression configuration. Supported types are bzip2, gzip, and
        none. The default remains bzip2.

    *   The release_hashref file is no longer created. It has been replaced
        with release_metadata.json. This contains more information and requires
        cartage-rack 2.0 to display.

    *   Plug-ins have changed:

        *   Plug-in capabilities must be provided in the gem path
            <tt>lib/cartage/plugins</tt>.

        *   Plug-ins declare their feature support to indicate the points that
            they will be called during the packaging process.

        *   Plug-in commands must be provided in the gem path
            <tt>lib/cartage/commands</tt>. These commands are always available.

        *   Plug-ins are currently automatically enabled on discovery and may
            be explicitly disabled in configuration. Future versions of Cartage
            will support explicit plug-in selection in configuration.

    *   Made more functions public for use by plug-ins.

    *   Removed support for default configuration files outside of a project
        directory. Only <tt>config/cartage.yml</tt>, <tt>.cartage.yml</tt>, and
        <tt>cartage.yml</tt> will be read now.
        <tt>$HOME/.config/cartage.yml</tt>, <tt>$HOME/.cartage.yml</tt>, and
        <tt>/etc/cartage.yml</tt> are no longer read. The previous behaviour
        can be obtained with ERB insertion into one of the project-specific
        files, as shown below. This pattern is not recommended.

            ---
            # cartage.yml
            % candidates = []
            % candidates << "#{ENV['HOME']}/.config/cartage.yml"
            % candidates << "#{ENV['HOME']}/.cartage.yml"
            % candidates << '/etc/cartage.yml'
            % global = candidate.select { |c| File.exist?(c) }
            <%= Cartage::Config.import(global) %>

    *   Extracted bundler support as a new gem,
        [cartage-bundler]{https://github.com/KineticCafe/cartage-bundler}.

    *   Extracted tarball building as a built-in plug-in,
        Cartage::BuildTarball.

*   Added Cartage::Minitest to provide methods to assist with testing Cartage
    and plug-ins using Minitest.

### 1.2 / 2015-05-27

*   1 minor enhancement:

    *   Added the chosen timestamp as the second line of the release hashref
        files.

*   2 minor bugfixes:

    *   Fixed {#3}[https://github.com/KineticCafe/issues/3] so that spec and
        feature directories are excluded by default. Provided by @jsutlovic.
    *   Fixed {#5}[https://github.com/KineticCafe/pulls/5] so that the manifest
    *   is deduplicated prior to write. Provided by @jsutlovic.

### 1.1.1 / 2015-03-26

*   1 minor bugfix

    *   Fixed a Ruby syntax issue with Ruby 2.0.

### 1.1 / 2015-03-26

*   1 major enhancement

    *   Added a Cartage::StatusError with an exitstatus support.
        Cartage::QuietError is now based on this.

*   1 minor bugfix

    *   Restored an accidentally removed method,
        Cartage::#create_bundle_cache.

*   2 documentation improvements

    *   Identified postbuild script stages.

    *   Improved the Slack notifier example postbuild script.

### 1.0 / 2015-03-24

*   1 major enhancement

    *   Birthday!
