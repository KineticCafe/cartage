# frozen_string_literal: true

require 'pathname'
require 'json'

require 'cartage/core'
require 'cartage/plugin'
require 'cartage/config'

##
# Cartage, a reliable package builder.
class Cartage
  VERSION = '2.0.rc1' #:nodoc:

  # Creates a new Cartage instance. If provided a Cartage::Config object in
  # +config+, sets the configuration and resolves it. If +config+ is not
  # provided, the default configuration will be loaded.
  def initialize(config = nil)
    self.config = config || Cartage::Config.load(:default)
  end

  ##
  # :attr_accessor: name
  #
  # The name of the package to create. Defaults to #default_name.

  ##
  # :method: default_name
  #
  # The default name of the package to be created, derived from the
  # repository's Git URL.

  attr_accessor_with_default :name, default: -> { File.basename(repo_url, '.git') }

  ##
  # :attr_accessor: root_path
  #
  # The root path for the application.

  ##
  # :method: default_root_path
  #
  # The default root path of the package, the top-level path of the Git
  # repository.

  attr_reader_with_default :root_path do
    Pathname(%x(git rev-parse --show-cdup).chomp).expand_path
  end

  ##
  def root_path=(v) #:nodoc:
    reset_computed_values
    @root_path = Pathname(v).expand_path
  end

  ##
  # :attr_accessor: target
  #
  # The target where the final Cartage package will be created.

  ##
  # :method: default_target
  #
  # The default target of the package, './tmp'.

  attr_accessor_with_default :target,
    transform: ->(v) { Pathname(v) },
    default: -> { Pathname('tmp') }

  ##
  # :attr_accessor: timestamp
  #
  # The timestamp to be applied to the final package name.

  ##
  # :method: default_timestamp
  #
  # The default timestamp.

  attr_accessor_with_default :timestamp, default: -> {
    Time.now.utc.strftime('%Y%m%d%H%M%S')
  }

  ##
  # :attr_accessor: compression
  #
  # The compression to be applied to any tarballs created (either the final
  # tarball or the dependency cache tarball).

  ##
  def compression
    unless defined?(@compression)
      @compression = :bzip2
      reset_computed_values
    end
    @compression
  end

  ##
  def compression=(value) #:nodoc:
    case value
    when :bzip2, :none, :gzip, 'bzip2', 'none', 'gzip'
      @compression = value
      reset_computed_values
    else
      fail ArgumentError, "Invalid compression type #{value.inspect}"
    end
  end

  # If +true+, dependencies will not be cached.
  attr_accessor :disable_dependency_cache

  ##
  # :attr_reader: dependency_cache
  #
  # The path to the tarball of vendored dependencies in the working path.
  #
  # Vendored dependencies vary by build system. With Ruby and Bundler, this
  # would be the <tt>vendor/bundle</tt> path; with npm, this would be the
  # <tt>node_modules</tt> path.

  ##
  def dependency_cache
    self.dependency_cache_path = tmp_path unless defined?(@dependency_cache)
    @dependency_cache
  end

  ##
  # :attr_accessor: dependency_cache_path
  #
  # Reads or sets the vendored dependency cache path. This is where the tarball
  # of vendored dependencies in the working path will reside.
  #
  # On a CI system, this should be written somewhere that the CI system uses
  # for build caching. On Semaphore CI, this would be
  # <tt>$SEMAPHORE_CACHE</tt>.

  ##
  def dependency_cache_path
    self.dependency_cache_path = tmp_path unless defined?(@dependency_cache_path)
    @dependency_cache_path
  end

  ##
  def dependency_cache_path=(path) #:nodoc:
    @dependency_cache_path = Pathname(path || tmp_path).expand_path
    @dependency_cache = @dependency_cache_path.
      join("dependency-cache.tar#{tar_compression_extension}")
  end

  # Commands that normally output data will have that output suppressed.
  attr_accessor :quiet

  # Commands will be run with extra information.
  attr_accessor :verbose

  # The cartage configuration object, implemented as a recursive OpenStruct.
  # This can return just the subset of configuration for a command or plug-in
  # by providing the +for_plugin+ or +for_command+ parameters.
  def config(for_plugin: nil, for_command: nil)
    if for_plugin && for_command
      fail ArgumentError, 'Cannot get config for plug-in and command together'
    elsif for_plugin
      @config.dig(:plugins, for_plugin.to_sym) || OpenStruct.new
    elsif for_command
      @config.dig(:commands, for_command.to_sym) || OpenStruct.new
    else
      @config
    end
  end

  # The config file. This should not be used by clients.
  def config=(cfg) # :nodoc:
    fail ArgumentError, 'No config provided' unless cfg
    @plugins = Plugins.new
    @config = cfg
    resolve_config!
  end

  # The release metadata that will be written for the package.
  def release_metadata
    @release_metadata ||= {
      package: {
        name: name,
        repo: {
          type: 'git', # Hardcoded until we have other support
          url: repo_url
        },
        hashref: release_hashref,
        timestamp: timestamp
      }
    }
  end

  # Return the release hashref.
  def release_hashref
    @release_hashref ||= %x(git rev-parse HEAD).chomp
  end

  # The repository URL.
  def repo_url
    unless defined? @repo_url
      @repo_url = %x(git remote show -n origin).
        match(/\n\s+Fetch URL: (?<fetch>[^\n]+)/)[:fetch]
    end
    @repo_url
  end

  # The temporary path.
  def tmp_path
    @tmp_path ||= root_path.join('tmp')
  end

  # The working path for the job, in #tmp_path.
  def work_path
    @work_path ||= tmp_path.join(name)
  end

  # The final name
  def final_name
    @final_name ||= tmp_path.join("#{name}-#{timestamp}")
  end

  # The path to the resulting release-metadata.json file.
  def final_release_metadata_json
    @final_release_metadata_json ||= Pathname("#{final_name}-release-metadata.json")
  end

  # A utility method for Cartage plug-ins to display a +message+ only if
  # verbose is on. Unless the command implemented by the plug-in is output
  # only, this should be used.
  def display(message)
    __display(message)
  end

  # A utility method for Cartage plug-ins to run a +command+ in the shell. Uses
  # IO.popen.
  def run(command)
    display command.join(' ')

    IO.popen(command + [ err: %i(child out) ]) do |io|
      __display(io.read(128), partial: true, verbose: true) until io.eof?
    end

    fail StandardError, "Error running '#{command.join(' ')}'" unless $?.success?
  end

  # Returns the registered plug-ins, once configuration has been resolved.
  def plugins
    @plugins ||= Plugins.new
  end

  # Create the release package(s).
  #
  # Requests:
  # *  +:vendor_dependencies+ (#vendor_dependencies, #path)
  # *  +:pre_build_package+
  # *  +:build_package+
  # *  +:post_build_package+
  def build_package
    # Force timestamp to be initialized before anything else. This gives us a
    # stable timestamp for the process.
    timestamp
    # Prepare the work area: copy files from root_path to work_path based on
    # the resolved Manifest.txt.
    prepare_work_area
    # Anything that has been modified locally needs to be reset.
    restore_modified_files
    # Save both the final release metadata and the in-package release metadata.
    save_release_metadata
    # Vendor the dependencies for the package.
    vendor_dependencies
    # Request that supporting plug-ins build the package.
    request_build_package
  end

  # Returns the flag to use with +tar+ given the value of +compression+.
  def tar_compression_flag
    case compression
    when :bzip2, 'bzip2', nil
      'j'
    when :gzip, 'gzip'
      'z'
    when :none, 'none'
      ''
    end
  end

  # Returns the extension to use with +tar+ given the value of +compression+.
  def tar_compression_extension
    case compression
    when :bzip2, 'bzip2', nil
      '.bz2'
    when :gzip, 'gzip'
      '.gz'
    when :none, 'none'
      ''
    end
  end

  private

  attr_writer :release_hashref

  def resolve_config!
    fail 'No configuration' unless config

    Cartage::Plugin.load_for(singleton_class)

    self.disable_dependency_cache = config.disable_dependency_cache
    self.quiet = config.quiet
    self.verbose = config.verbose

    maybe_assign :name, config.name
    maybe_assign :target, config.target
    maybe_assign :root_path, config.root_path
    maybe_assign :timestamp, config.timestamp
    maybe_assign :dependency_cache_path, config.dependency_cache_path
    maybe_assign :release_hashref, config.release_hashref

    Cartage::Plugin.each do |name|
      next unless respond_to?(name)
      plugin = send(name) or next
      plugin.send(:resolve_config!, config(for_plugin: name))

      plugins.add plugin
    end

    plugins.freeze
  end

  def maybe_assign(name, value)
    return if value.nil? || (value.respond_to?(:empty?) && value.empty?) ||
        instance_variable_defined?(:"@#{name}")
    send(:"#{name}=", value)
  end

  def __display(message, partial: false, verbose: self.verbose)
    return unless verbose && !quiet

    if partial
      print message
    else
      puts message
    end
  end

  def reset_computed_values
    instance_variable_set(:@tmp_path, nil)
    instance_variable_set(:@final_name, nil)
    instance_variable_set(:@final_release_metadata_json, nil)
    instance_variable_set(:@release_metadata, nil)
    instance_variable_set(:@work_path, nil)
    self.dependency_cache_path = dependency_cache_path
  end

  def prepare_work_area
    display 'Preparing cartage work area...'

    work_path.rmtree if work_path.exist?
    work_path.mkpath

    manifest.resolve(root_path) do |file_list|
      tar_cf_cmd = [
        'tar', 'cf', '-', '-C', parent, '-h', '-T', file_list
      ].map(&:to_s)

      tar_xf_cmd = [
        'tar', 'xf', '-', '-C', work_path, '--strip-components=1'
      ].map(&:to_s)

      IO.popen(tar_cf_cmd) do |cf|
        IO.popen(tar_xf_cmd, 'w') do |xf|
          xf.write cf.read
        end

        fail StandardError, "Error running #{tar_xf_cmd.join(' ')}" unless $?.success?
      end

      fail StandardError, "Error running #{tar_cf_cmd.join(' ')}" unless $?.success?
    end
  end

  def save_release_metadata
    display 'Saving release metadata...'
    json = JSON.generate(release_metadata)
    work_path.join('release-metadata.json').write(json)
    final_release_metadata_json.write(json)
  end

  def restore_modified_files
    %x(git status -s).
      split($/).
      map(&:split).
      select { |s, _f| s !~ /\?/ }.
      map(&:last).
      each { |file|
        restore_modified_file file
      }
  end

  def restore_modified_file(filename)
    command = [
      'git', 'show', "#{release_hashref}:#{filename}"
    ]

    IO.popen(command) do |show|
      work_path.join(filename).open('w') { |f|
        f.puts show.read
      }
    end
  end

  def vendor_dependencies
    extract_dependency_cache

    plugins.request(:vendor_dependencies)

    create_dependency_cache(
      plugins.request_map(:vendor_dependencies, :path).compact.flatten
    )
  end

  def extract_dependency_cache
    return if disable_dependency_cache || !dependency_cache.exist?
    run %W(tar xf#{tar_compression_flag} #{dependency_cache} -C #{work_path})
  end

  def create_dependency_cache(paths = [])
    return if disable_dependency_cache || paths.empty?
    run [
      'tar',
      "cf#{tar_compression_flag}",
      dependency_cache,
      '-C',
      work_path,
      *paths
    ].map(&:to_s)
  end

  def parent
    @parent ||= root_path.parent
  end

  def realize!
    repo_url
    root_path
    release_hashref
    timestamp
  end

  def request_build_package
    plugins.request(:pre_build_package)
    plugins.request(:build_package)
    plugins.request(:post_build_package)
  end
end

require_relative 'cartage/config'
