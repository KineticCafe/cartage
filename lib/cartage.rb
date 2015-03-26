require 'pathname'

# Cartage, a package builder.
class Cartage
  VERSION = '1.1' #:nodoc:

  # Plug-in commands that want to return a specific exit code should use
  # Cartage::StatusError to wrap the error.
  class StatusError < StandardError
    # Initialize the exception with +exitstatus+ and the exception to wrap.
    def initialize(exitstatus, exception_or_message)
      super(exception_or_message) if exception_or_message
      @exitstatus = exitstatus
    end

    # The exit status to be returned from this exception.
    attr_reader :exitstatus
  end

  # Plug-in commands that want to return a non-zero exit code without a message
  # should raise Cartage::QuietError.new(exitstatus).
  class QuietError < StatusError
    # Initialize the exception with +exitstatus+.
    def initialize(exitstatus)
      super(exitstatus, nil)
    end

    attr_reader :exitstatus
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

  ##
  # :attr_accessor: root_path
  #
  # The root path for the application.

  ##
  # :method: default_root_path
  #
  # The default root path of the package, the top-level path of the Git
  # repository.

  ##
  # :attr_accessor: target
  #
  # The target where the final Cartage package will be created.

  ##
  # :method: default_target
  #
  # The default target of the package, './tmp'.

  ##
  # :attr_accessor: timestamp
  #
  # The timestamp to be applied to the final package name.

  ##
  # :method: default_timestamp
  #
  # The default timestamp.

  ##
  # :attr_accessor: without_groups
  #
  # The environments to exclude from a bundle install.

  ##
  # :method: default_without_environments
  #
  # The default environments to exclude from a bundle install. The default is
  # <tt>[ 'test', 'development' ]</tt>.

  # Commands that normally output data will have that output suppressed.
  attr_accessor :quiet

  # Commands will be run with extra information.
  attr_accessor :verbose

  # The environment to be used when resolving configuration options from a
  # configuration file. Cartage configuration files do not usually have
  # environment partitions, but if they do, use this to select the environment
  # partition.
  attr_accessor :environment

  # The Config object. If +with_environment+ is +true+ (the default) and
  # #environment has been set, only the subset of the config matching
  # #environment will be returned. If +with_environment+ is +false+, the full
  # configuration will be returned.
  #
  # If +for_plugin+ is specified, only the subset of the config for the named
  # plug-in will be returned.
  #
  #     # Assume that #environment is 'development'.
  #     cartage.config
  #       # => base_config[:development]
  #     cartage.config(with_environment: false)
  #       # => base_config
  #     cartage.config(for_plugin: 's3')
  #       # => base_config[:development][:plugins][:s3]
  #     cartage.config(for_plugin: 's3', with_environment: false)
  #       # => base_config[:plugins][:s3]
  def config(with_environment: true, for_plugin: nil)
    env  = environment.to_sym if with_environment && environment
    plug = for_plugin.to_sym if for_plugin

    cfg = if env
            base_config[env]
          else
            base_config
          end

    cfg = cfg.plugins[plug] if plug && cfg.plugins
    cfg
  end

  # The configuration file to read. This should not be used by clients.
  attr_writer :load_config #:nodoc:

  # The base config file. This should not be used by clients.
  attr_accessor :base_config #:nodoc:

  def initialize #:nodoc:
    @load_config = :default
  end

  # Create the package.
  def pack
    timestamp # Force the timestamp to be set now.
    prepare_work_area
    save_release_hashref
    fetch_bundler
    install_vendor_bundle
    restore_modified_files
    build_final_tarball
  end

  # Set or return the bundle cache. The bundle cache is a compressed tarball of
  # <tt>vendor/bundle</tt> in the working path.
  #
  # If it exists, it will be extracted into <tt>vendor/bundle</tt> before
  # <tt>bundle install --deployment</tt> is run, and it will be created after
  # the bundle has been installed. In this way, bundle installation works
  # almost the same way as Capistrano’s shared bundle concept as long as the
  # path to the bundle_cache has been set to a stable location.
  #
  # On Semaphore CI, this should be created relative to
  # <tt>$SEMAPHORE_CACHE</tt>.
  #
  #   cartage pack --bundle-cache $SEMAPHORE_CACHE
  def bundle_cache(location = nil)
    if location || !defined?(@bundle_cache)
      @bundle_cache = Pathname(location || tmp_path).
        join('vendor-bundle.tar.bz2').expand_path
    end
    @bundle_cache
  end

  # Return the release hashref. If the optional +save_to+ parameter is
  # provided, the release hashref will be written to the specified file.
  def release_hashref(save_to: nil)
    @release_hashref ||= %x(git rev-parse HEAD).chomp
    File.open(save_to, 'w') { |f| f.write @release_hashref } if save_to
    @release_hashref
  end

  # The repository URL.
  def repo_url
    unless defined? @repo_url
      origin = %x(git remote show -n origin)
      match = origin.match(%r{\n\s+Fetch URL: (?<fetch>[^\n]+)})
      @repo_url = match[:fetch]
    end
    @repo_url
  end

  # The path to the resulting package.
  def final_tarball
    @final_tarball ||= Pathname("#{final_name}.tar.bz2")
  end

  # The path to the resulting release_hashref.
  def final_release_hashref
    @final_release_hashref ||=
      Pathname("#{final_name}-release-hashref.txt")
  end

  # A utility method for Cartage plug-ins to display a message only if verbose
  # is on. Unless the command implemented by the plug-in is output only, this
  # should be used.
  def display(message)
    __display(message)
  end

  private
  def resolve_config!(*with_plugins)
    return unless @load_config
    @base_config = Cartage::Config.load(@load_config)

    cfg = config
    maybe_assign :target, cfg.target
    maybe_assign :name, cfg.name
    maybe_assign :root_path, cfg.root_path
    maybe_assign :timestamp, cfg.timestamp
    maybe_assign :without_groups, cfg.without

    bundle_cache(cfg.bundle_cache) unless cfg.bundle_cache.nil? ||
      cfg.bundle_cache.empty?

    with_plugins.each do |name|
      next unless respond_to? name
      plugin = send(name)

      next unless plugin
      plugin.send(:resolve_config!, config(for_plugin: name))
    end
  end

  def maybe_assign(name, value)
    return if value.nil? || value.empty? ||
      instance_variable_defined?(:"@#{name}")
    send(:"#{name}=", value)
  end

  def __display(message, partial: false, verbose: verbose())
    return unless verbose && !quiet

    if partial
      print message
    else
      puts message
    end
  end

  def run(command)
    display command.join(' ')

    IO.popen(command + [ err: [ :child, :out ] ]) do |io|
      __display(io.read(128), partial: true, verbose: true) until io.eof?
    end

    unless $?.success?
      raise StandardError, "Error running '#{command.join(' ')}'"
    end
  end

  def prepare_work_area
    display "Preparing cartage work area..."

    work_path.rmtree if work_path.exist?
    work_path.mkpath

    xf_status = cf_status = nil

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

        unless $?.success?
          raise StandardError, "Error running #{tar_xf_cmd.join(' ')}"
        end
      end

      unless $?.success?
        raise StandardError, "Error running #{tar_cf_cmd.join(' ')}"
      end
    end
  end

  def save_release_hashref
    display 'Saving release hashref...'
    release_hashref save_to: work_path.join('release_hashref')
    release_hashref save_to: final_release_hashref
  end

  def extract_bundle_cache
    run %W(tar xfj #{bundle_cache} -C #{work_path}) if bundle_cache.exist?
  end

  def create_bundle_cache
    run %W(tar cfj #{bundle_cache} -C #{work_path} vendor/bundle)
  end

  def install_vendor_bundle
    extract_bundle_cache

    Bundler.with_clean_env do
      Dir.chdir(work_path) do
        run %w(bundle install --jobs=4 --deployment --clean --without) +
          without_groups
      end
    end

    create_bundle_cache
  end

  def restore_modified_files
    %x(git status -s).split($/).map(&:split).map(&:last).each { |file|
      restore_modified_file file
    }
  end

  def fetch_bundler
    Dir.chdir(work_path) do
      run %w(gem fetch bundler)
    end
  end

  def build_final_tarball
    run %W(tar cfj #{final_tarball} -C #{tmp_path} #{name})
  end

  def work_path
    @work_path ||= tmp_path.join(name)
  end

  def clean
    [ work_path ] + final
  end

  def final
    [ final_tarball, final_release_hashref ]
  end

  def parent
    @parent ||= root_path.parent
  end

  def restore_modified_file(filename)
    command = [
      'git', 'show', "#{release_hashref}:#{filename}"
    ]

    IO.popen(command) do |show|
      work_path.join(filename).open('w') { |f| f.write show.read }
    end
  end

  def tmp_path
    @tmp_path ||= root_path.join('tmp')
  end

  def final_name
    @final_name ||= tmp_path.join("#{name}-#{timestamp}")
  end

  class << self
    private

    def lazy_accessor(sym, default: nil, setter: nil, &block)
      ivar = :"@#{sym}"
      wsym = :"#{sym}="
      dsym = :"default_#{sym}"

      if default.nil? && block.nil?
        raise ArgumentError, "No default provided."
      end

      if setter && !setter.respond_to?(:call)
        raise ArgumentError, "setter must be callable"
      end

      setter ||= ->(v) { v }

      dblk = if default.respond_to?(:call)
               default
             elsif default.nil?
               block
             else
               -> { default }
             end

      define_method(sym) do
        instance_variable_get(ivar) || send(dsym)
      end

      define_method(wsym) do |value|
        instance_variable_set(ivar, setter.call(value || send(dsym)))
      end

      define_method(dsym, &dblk)
    end
  end

  lazy_accessor :name, default: -> { File.basename(repo_url, '.git') }
  lazy_accessor :root_path, setter: ->(v) { Pathname(v).expand_path },
    default: -> { Pathname(%x(git rev-parse --show-cdup).chomp).expand_path }
  lazy_accessor :target, setter: ->(v) { Pathname(v) },
    default: -> { Pathname('tmp') }
  lazy_accessor :timestamp, default: -> {
    Time.now.utc.strftime("%Y%m%d%H%M%S")
  }
  lazy_accessor :without_groups, setter: ->(v) { Array(v) },
    default: -> { %w(development test) }
  lazy_accessor :base_config, default: -> { OpenStruct.new }
end

class << Cartage
  # Run the Cartage command-line program.
  def run(args) #:nodoc:
    require_relative 'cartage/plugin'
    Cartage::Plugin.load
    Cartage::Plugin.decorate(Cartage)

    cartage = Cartage.new

    cli = CmdParse::CommandParser.new(handle_exceptions: true)
    cli.main_options.program_name = 'cartage'
    cli.main_options.version = Cartage::VERSION.split(/\./)
    cli.main_options.banner = 'Manage releaseable packages.'

    cli.global_options do |opts|
      # opts.on('--[no-]quiet', 'Silence normal command output.') { |q|
      #   cartage.quiet = !!q
      # }
      opts.on('--[no-]verbose', 'Show verbose output.') { |v|
        cartage.verbose = !!v
      }
      opts.on(
        '-E', '--environment [ENVIRONMENT]', <<-desc
Set the environment to be used when necessary. If an environment name is not
provided, it will check the values of $RAILS_ENV and RACK_ENV. If neither is
set, this option is ignored.
        desc
      ) { |e| cartage.environment = e || ENV['RAILS_ENV'] || ENV['RACK_ENV'] }
      opts.on(
        '-C', '--[no-]config-file load_config', <<-desc
Configure Cartage from a default configuration file or a specified
configuration file.
        desc
      ) { |c| cartage.load_config = c }
    end

    cli.add_command(CmdParse::HelpCommand.new)
    cli.add_command(CmdParse::VersionCommand.new)
    cli.add_command(Cartage::PackCommand.new(cartage))

    Cartage::Plugin.registered.each do |plugin|
      if plugin.respond_to?(:commands)
        Array(plugin.commands).flatten.each do |command|
          registered_commands << command
        end
      end
    end

    registered_commands.uniq.each { |cmd| cli.add_command(cmd.new(cartage)) }
    cli.parse
    return 0
  rescue Exception => exception
    show_message_for exception, for_cartage: cartage
    return exitstatus_for(exception)
  end

  # Set options common to anything that builds a package (that is, it calls
  # Cartage#pack).
  def common_build_options(opts, cartage)
    opts.on(
      '-t', '--target PATH',
      'The build package will be placed in PATH, which defaults to \'tmp\'.'
    ) { |t| cartage.target = t }
    opts.on(
      '-n', '--name NAME',
      "Set the package name. Defaults to '#{cartage.default_name}'."
    ) { |n| cartage.name = n }
    opts.on(
      '-r', '--root-path PATH',
      'Set the root path. Defaults to the repository root.'
    ) { |r| cartage.root_path = r }
    opts.on(
      '--timestamp TIMESTAMP',
      'The timestamp used for the final package.'
    ) { |t| cartage.timestamp = t }
    opts.on(
      '--bundle-cache PATH',
      'Set the bundle cache path.'
    ) { |b| cartage.bundle_cache(b) }
    opts.on(
      '--without GROUP1,GROUP2', Array,
      'Set the groups to be excluded from bundle installation.',
    ) { |w| cartage.without_environments = w }
  end

  private
  def registered_commands
    @registered_commands ||= []
  end

  def exitstatus_for(exception)
    if exception.respond_to? :exitstatus
      exception.exitstatus
    else
      2
    end
  end

  def show_message_for(exception, for_cartage:)
    unless exception.kind_of?(Cartage::QuietError)
      $stderr.puts "Error:\n    " + exception.message
      $stderr.puts exception.backtrace.join("\n") if for_cartage.verbose
    end
  end
end

require_relative 'cartage/config'
