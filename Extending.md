# Extending Cartage

Cartage is designed for extension. There are two distinct *types* of extension
that can be written: *commands* and *plug-ins*. Most *command* extensions will
implement a *plug-in* extension, but Cartage can be extended with either
mechanism on its own. For both *commands* and *plug-ins* there is automatic
discovery and activation.

## Command Extensions

Command extensions add new commands and subcommands to the Cartage CLI
(`bin/cartage`). The Cartage CLI is written with the [GLI][] DSL, so all of the
features present in GLI can be used to add commands to Cartage itself. Commands
are discovered by placing a command definition file in `lib/cartage/commands`
in the gem containing the command extension.

### Defining a Command

New commands *extend* Cartage::CLI, opening a context where the GLI DSL can be
used to create a new command. Outside of the new command block, it is
recommended that only `desc`, `long_desc`, `arg`, and `command` be used since
there is no way of adding support for new global switches or flags.

```ruby
Cartage::CLI.extend do
  # Define the commands here.
  desc 'A new command'
  long_desc 'A long description for the new command'
  arg :maybe, :optional
  arg :yes # required by default
  arg :items, :multiple
  command 'newcommand' do |echo|
    echo.desc 'Enable fuzz mode.'
    echo.switch :fuzz

    echo.desc 'Fuzz level.'
    echo.flag 'fuzz-level', arg_name: :LEVEL, default_value: 0
    echo.action do |global, options, args|
      # Whatever the new command does should be done here.
    end
  end
end
```

It is recommended that a command extension add only one new command with
subcommands to handle more complex operations.

```ruby
Cartage::CLI.extend do
  command 'newcommand' do |echo|
    echo.command 'subcommand' do |sc|
      sc.action do |global, options, args|
        # subcommand actions
      end
    end

    echo.default_command :subcommand
  end
end
```

### Global Cartage Instance

Each defined command operates in the same global context and has access to a
method (`cartage`) that returns the operating instance of Cartage for the
execution of the `cartage` command.

```ruby
Cartage::CLI.extend do
  desc 'Echo the provided text'
  arg :TEXT, :multiple
  command 'echo' do |echo|
    echo.desc 'Suppress newlines'
    echo.switch [ :c, 'newlines' ], default: true, negatable: false
    echo.action do |_g, options, args|
      unless cartage.quiet
        message = args.join(' ')
        if options['no-newlines'] || cartage.config(for_command: 'echo').no_newlines
          puts message
        else
          print message
        end
      end
    end
  end
end
```

In the example above, the `echo` command checks the global configuration for
the value of the `quiet` switch, and the command options and configuration for
whether newlines should be included in the output. Note the use of
Cartage#config with the `for_command` keyword parameter.

### Exiting the Command

If the command is successful, completing its action block without raising an
exception will be sufficient. If an exception is thrown, it will be caught, its
message displayed, and `cartage` will exit with a non-zero exit status.

Cartage::CLI provides three *special* exceptions:

Cartage::CLI::QuietExit
:   This will abort or exit the command with the provided exit status. No message
will be displayed. This is used in `cartage manifest check`.

Cartage::CLI::CustomExit
:   An alias for GLI::CustomExit. Raised with a message and an exit status. The
message will be displayed, and the exit status will be returned. This should be
used for *failure* of the command.

Cartage::CLI::CommandException
:   An alias for GLI::CommandException. This exception is similar to CustomExit,
but should be used when there is a configuration issue, or a conflict in flags
or switches. It requires three parameters: the message to display, the command
name for help purposes, and the exit status.

### Example (`info` Command)

Below is an example command and sub-commands, `cartage info`. This has
limited utility, but will illustrate how commands are created in Cartage. This
example is usable, as the `info` command is a hidden command on `cartage`.

```ruby
# Call Cartage::CLI.extend to add the commands defined in the block.
Cartage::CLI.extend do
  # Use +desc+ to provide a description about the next command.
  desc 'Show information about Cartage itself'

  # Use +long_desc+ to provide a long description about the next command that
  # can # be included in a generated RDoc file.
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
          plugs.map! { |plug| "* #{plug.plugin_name} (#{plug.version})" }
          puts <<-plugins
Active Plug-ins:

#{plugs.join("\n")}
          plugins
        end
      end
    end
  end
end
```

## Plug-In Extensions

Cartage plug-ins:

*  are automatically discovered and loaded;
*  are accessible from and initialized with an owning Cartage instance;
*  have a namespace in the Cartage configuration file; and
*  may implement feature requests or offers (see below).

When explaining how to build plug-ins, we will be examining three different
plug-ins:

*   Cartage::Manifest manages the `Manifest.txt` file and the `.cartignore`
    file that indicates what files will be included in the release package, and
    is for use with the `cartage manifest` family of commands.

    *   No configuration
    *   Bundled with Cartage (`lib/cartage/plugins/manifest.rb`)

*   Cartage::BuildTarball is responsible for building the final package after
    Cartage prepares the work area.

    *   No configuration
    *   Implements feature requests
    *   Implements feature offers
    *   Bundled with Cartage (`lib/cartage/plugins/build_tarball.rb`)

*   Cartage::Bundler is responsible for vendoring Bundler dependencies for Ruby
    projects. It was originally part of Cartage 1.x, but has been extracted to
    its own gem.

    *   Has configuration
    *   Implements feature offers
    *   Gem [cartage-bundler][] (`lib/cartage/plugins/bundler.rb`)

### Plug-In Discovery and Initialization

Plug-ins are placed in files that are found in `lib/cartage/plugins` and are
found in the `$LOAD_PATH`[^1]. The code in these files should define a class
that inherits from Cartage::Plugin.

When a Cartage instance is created, the plug-in will be loaded and the
resulting plug-in class will be added to the instance as a method matching the
name of the class of the plug-in. Given an instance of Cartage called
`cartage`:

*   Cartage::Manifest is available as `cartage.manifest`.
*   Cartage::BuildTarball is available as `cartage.build_tarball`.
*   Cartage::Bundler is available as `cartage.bundler`.

### Plug-In Configuration

Each plug-in has its own configuration dictionary as part of the
Cartage::Config dictionary, under the `plugins` dictionary. When the Cartage
configuration file is loaded and resolved for Cartage, the relevant section of
the Cartage dictionary is provided to the plug-in.

Any plug-in's configuration dictionary can be requested through Cartage#config
with the `for_plugin` keyword parameter:

```ruby
cartage.config(for_plugin: :bundler)
```

Plug-ins should implement `#resolve_plugin_config!` to finalize configuration
as appropriate.

*   Cartage::Manifest only uses core Cartage configuration.
*   Cartage::BuildTarball only uses core Cartage configuration.
*   Cartage::Bundler uses its configuration section. For full details, read the
    documentation of [`cartage-bundler`][]. `#resolve_plugin_config!` resolves
    the Gemfile and the gem group exclusions.

    ```yaml
    ---
    commands: {}
    plugins:
      bundler:
        without_groups:
          - assets
          - development
          - test
    ```

    This is handled with:

    ```ruby
    # Cartage::Bundler is a +vendor_dependencies+ plug-in for Cartage.
    class Cartage::Bundler < Cartage::Plugin
      private

      attr_reader :gemfile, :without_groups

      def resolve_plugin_config!(config)
        @gemfile = cartage.root_path.join(config.gemfile || 'Gemfile').expand_path
        @without_groups = Array(config.without_groups || %w(development test))
      end
    end
    ```

### Disabling Plug-Ins

All discovered plug-ins are enabled by default and can be disabled in the
plug-in's configuration dictionary with the key `disabled`. Note that disabling
a plug-in only has meaning for plug-ins that implement feature offers, as
disabled plug-ins will be skipped when features are requested.

```yaml
---
plugins:
  bundler:
    disabled: true
```

Plug-ins may have additional conditions that may cause them to be disabled.
Cartage::Bundler is disabled if the `Gemfile` does not exist.

```ruby
class Cartage::Bundler < Cartage::Plugin
  # Cartage::Bundler is only enabled if the Gemfile exists.
  def disabled?
    super || !gemfile.exist?
  end
end
```

### Feature Requests and Offers

Cartage plug-ins can implement feature *requests* or *offers* to provide
functionality that is loosely-coupled and dynamically discovered. Cartage
commands or plug-ins will broadcast feature *requests* to all enabled plug-ins;
any plug-in which *offers* that feature will then have appropriate methods
called to perform the plug-in's implementation of that feature.

A *feature* is simply a label that plug-ins *request* or *offer*. An example is
useful, based on Cartage#build_package (run by `cartage pack`).

1.  Cartage *requests* `:vendor_dependencies`. Cartage::Bundler *offers*
    `:vendor_dependencies`. In turn, `#vendor_dependencies` (which ultimately
    runs `bundle install`) and `#path` will be called on Cartage::Bundler.

2.  Cartage *requests* `:pre_build_package`.

3.  Cartage *requests* `:build_package`. Cartage::BuildTarball *offers*
    `:build_package`, so `#build_package` will be called.

4.  Cartage::BuildTarball *requests* `:pre_build_tarball`.

5.  Cartage::BuildTarball builds the tarball.

6.  Cartage::BuildTarball *requests* `:post_build_tarball`.

7.  Cartage *requests* `:post_build_package`.

There is no fixed set of features, so any plug-in can request any feature. When
feature `:build_package` is requested (see [Requesting Features][]), the
collection of plugins is filtered for plugins that `#offer?(:build_package)`.

#### Offering Features

Most plug-ins will *offer* features. The easiest way to offer a particular
feature is to implement a public method that matches the name of the requested
feature[^2]. This is visible in Cartage::Bundler with `#vendor_dependencies`
and Cartage::BuildTarball with `#build_package`.

This works because feature *requests* will generally want to call a method of
the same name as the feature. The implementation of the `#offer?` test on
Cartage::Plugin makes this explicit.

```ruby
class Cartage::Plugin
  def offer?(name)
    enabled? && offer_feature?(name.to_sym)
  end

  private

  def offer_feature?(name)
    respond_to?(name)
  end
end
```

#### Requesting Features

Some plug-ins will *request* features. As shown in the outline above,
Cartage::BuildTarball *offers* the `:build_package` feature but *requests* two
additional features, `:pre_build_tarball` and `:post_build_tarball`. It does
this with Cartage::Plugins#request.

```ruby
class Cartage::BuildTarball < Cartage::Plugin
  def build_package
    cartage.plugins.request(:pre_build_tarball)
    # build the tarball here
    cartage.plugins.request(:post_build_tarball)
  end
end
```

Cartage::Plugins#request selects plugins that *offer* the feature, and then
loops over the selected plug-ins calling the feature method against them. The
implementation of #request is flexible enough to allow for a feature to be
requested and a different method to be called. This makes
Cartage::BuildTarball#build_package implementation look like:

```ruby
class Cartage::BuildTarball < Cartage::Plugin
  def build_package
    cartage.plugins.request(:pre_build_tarball, :pre_build_tarball)
    # build the tarball here
    cartage.plugins.request(:post_build_tarball, :pre_build_tarball)
  end
end
```

This works for a feature that requires multiple phases or steps, like
`:vendor_dependencies` does:

```ruby
class Cartage
  private

  def vendor_dependencies
    extract_dependency_cache

    plugins.request(:vendor_dependencies)

    create_dependency_cache(
      plugins.request_map(:vendor_dependencies, :path).compact.flatten
    )
  end
end
```

1.  Features can be requested using methods other than the name of the feature.
    `:vendor_dependencies` requires both `#vendor_dependencies` and `#path`.
2.  Cartage::Plugins#request_map is used to return the collection of results
    from the plug-ins *offering* the feature requested.

### *Feature Requests* from Cartage

The following *feature requests* are made when running Cartage:

#### `:vendor_dependencies`

Used during the setup of the work area to install external dependencies in the
package directory. Since external dependencies are usually described by a file,
a plug-in that offers `:vendor_dependencies` should disable itself if the
descriptive file cannot be found (such as the `Gemfile` or `package.json`).

> [cartage-bundler][] offers this for Ruby Bundler-based packages.

__Methods Required__

*   __`#vendor_dependencies`__: Invokes the tool that installs the external
    dependencies. This might run `bundle install` (for Ruby Bundler) or `npm
    install` (for Node.js NPM). It should be run in a way that only includes
    production dependencies, not development dependencies.

*   __`#path`__: Indicates the directory or directories, relative to the work
    area, where the external dependencies are installed. This might be
    `vendor/bundle` (for Ruby Bundler) or `node_modules` (for Node.js NPM).

#### `:pre_build_package`

Used to perform any other work that must be done for the contents of the
package to be ready for packaging. A plug-in could be written to perform asset
precompilation prior to packaging, for example.

Plug-ins offering `:pre_build_package` __should__ offer `:post_build_package`.

__Methods Required__

*   __`#pre_build_package`__: Performs the actions required to finalize package
    preparation.

#### `:post_build_package`

Used to perform any other work that must be done for the contents of the
package to be complete. A plug-in could be written to cryptographically sign
built packages, for example.

__Methods Required__

*   __`#post_build_package`__: Performs the actions required after package
    creation.

    If actions should be performed against any created packages, this should
    request `:build_package#package_name`.

    ```ruby
    cartage.plugins.request_map(:build_package, :package_name)
    ```

#### `:build_package`

Used to create a release package.

> This offered by Cartage as Cartage::BuildTarball.

__Methods Required__

*   __`#build_package`__: Performs the actions required to build a package for
    a particular format.

*   __`#package_name`__: Returns the name of the package that will be created.

#### `:pre_build_tarball`

Used to perform any other work that must be done for the contents of the
tarball to be ready for packaging.

Plug-ins offering `:pre_build_tarball` __should__ offer an implementation of
`:post_build_tarball` that reverses the effects of `:pre_build_tarball`. In
this way, side-effects between two `:build_package` plug-ins do not occur.

> Requested by Cartage::BuildTarball#build_package.

__Methods Required__

*   __`#pre_build_tarball`__: Performs the actions required before building the
    tarball.

#### `:post_build_tarball`

Used to perform any other work that must be after creating the tarball.
Recommended to revert actions performed in `:pre_build_tarball` plug-ins.

> Requested by Cartage::BuildTarball#build_package.

__Methods Required__

*   __`#post_build_tarball`__: Performs the actions required after building the
    tarball.

[GLI]: https://github.com/davetron5000/gli
[cartage-bundler]: https://github.com/KineticCafe/cartage-bundler
[Requesting Features]: #label-Requesting+Features

[^1]: Plug-ins are discovered using Rubygems APIs, where commands are
      discovered using `$LOAD_PATH`. While there is a difference, it has little
      practical impact.

[^2]: This may not be sufficient for all requested features. The
      `:vendor_dependencies` feature requires both `#vendor_dependencies` and 
      `#path` be implemented.
