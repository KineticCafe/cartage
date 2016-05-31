# cartage - Manage releaseable packages

Cartage provides a repeatable means to create a package for a server-side
application that can be used in deployment with a configuration tool like
Ansible, Chef, Puppet, or Salt.

## Global Options

__`-C`, `--config-file FILE`__

Use the specified Cartage configuration file.

Use the specified configuration file. If not specified, the configuration is
found relative to the current working directory (assumed to be the project
root) at one of the following locations:

1.  config/cartage.yml
2.  cartage.yml
3.  .cartage.yml

__`--dependency-cache-path PATH`__

The path where vendored dependencies will be cached between builds.

Dependencies for deployable packages are vendored. To reduce network calls and
build time, Cartage will cache the vendored dependencies in a tarball
(dependency-cache.tar.bz2) in this path.

__`-n`, `--name NAME`__

The name of the package.

The name of the package is used with the timestamp to create the final package
name. Defaults to the last part of the repo URL.

__`-r`, `--root-path PATH`__

The package source root path.

Where the package is built from. Defaults to the root of the repository.

__`-t`, `--target PATH`__

The destination of the created package.

Where the final package will be written. Defaults to 'tmp'.

__`--timestamp TIMESTAMP`__

The timestamp used for building the package.

The timestamp is used with the name of the package is used to create the final
package name.

__`-T`, `--trace`__

Show the backtrace when an error occurs.

__`--disable-dependency-cache`__

Disable the use of vendor dependency caching.

__`-q`, `--[no-]quiet`__

Silence normal output.

__`-v`, `--[no-]verbose`__

Show verbose output.

__`--version`__

Display the program version.

## Commands

### `help COMMAND`

Shows a list of commands or help for one command.

Gets help for the application or its commands. Can also list the commands in a
way helpful to creating a bash-style completion function.

*__Options__*

__`-c`__

List commands one per line, to assist with shell completion.

### `manifest`

Work with the Manifest.txt file

#### `manifest` Subcommands

##### `manifest cartignore`

Install or update the .cartignore file

*__Options__*

__`--mode MODE`__

Overwrite or merge an existing .cartignore. If specified, must be one of
`overwrite` or `merge`.

__`-f`, `--force`, `--overwrite`__

Overwrite an existing .cartignore (the same as `--mode overwrite`).

__`-m`, `--merge`__

Merge an existing .cartignore (the same as `--mode merge`).

##### `manifest check`

Check the Manifest.txt file against the current repository. If no command is
provided, this will run.

##### `manifest generate`, `manifest update`

Generate or update the Manifest.txt file.

##### `manifest show`

Show the files that will be included in the package.

### `pack`, `build`

Create a package with Cartage based on the Manifest.

*__Options__*

__`--skip-check`__

Skip checking the status of the Manifest before attempting to build the
package.
