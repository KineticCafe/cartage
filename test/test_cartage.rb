require 'minitest_config'

describe Cartage do
  before do
    @cartage = Cartage.new
  end

  describe '#name' do
    it 'defaults to #default_name' do
      stub_cartage_repo_url do
        assert_equal 'repo-url', @cartage.name
        assert_equal @cartage.default_name, @cartage.name
      end
    end

    it 'can be overridden' do
      stub_cartage_repo_url do
        @cartage.name = 'xyz'
        assert_equal 'xyz', @cartage.name
      end
    end
  end

  describe '#root_path' do
    it 'defaults to #default_root_path' do
      stub_backticks '/x/y/z' do
        assert_equal Pathname('/x/y/z'), @cartage.root_path
        assert_equal @cartage.default_root_path, @cartage.root_path
      end
    end

    it 'can be overridden and creates a Pathname' do
      stub_cartage_repo_url do
        @cartage.root_path = '/a/b/c'
        assert_equal Pathname('/a/b/c'), @cartage.root_path
      end
    end

    it 'expands the created Pathname' do
      stub_cartage_repo_url do
        @cartage.root_path = '/a/b/../c'
        assert_equal Pathname('/a/c'), @cartage.root_path
      end
    end
  end

  describe '#timestamp' do
    it 'defaults to #now.utc.strftime("%Y%m%d%H%M%S")' do
      stub Time, :now, -> { Time.new(2014, 12, 31, 23, 59, 59, "+00:00") } do
        assert_equal '20141231235959', @cartage.timestamp
        assert_equal @cartage.default_timestamp, @cartage.timestamp
      end
    end

    it 'does no validation of assigned values' do
      @cartage.timestamp = 'not a timestamp'
      assert_equal 'not a timestamp', @cartage.timestamp
    end
  end

  describe '#without_groups' do
    it 'defaults to %w(development test)' do
      assert_equal %w(development test), @cartage.without_groups
      assert_equal @cartage.default_without_groups, @cartage.without_groups
    end

    it 'wraps arrays correctly' do
      @cartage.without_groups = 'dit'
      assert_equal %w(dit), @cartage.without_groups
    end
  end

  describe '#base_config' do
    it 'defaults to an empty OpenStruct' do
      assert_equal OpenStruct.new, @cartage.base_config
      assert_equal @cartage.default_base_config, @cartage.base_config
      refute_same @cartage.default_base_config, @cartage.base_config
    end
  end

  describe '#config' do
    before do
      data = {
        x: 1,
        plugins: {
          test: {
            x: 2
          }
        },
        development: {
          x: 3,
          plugins: {
            test: {
              x: 4
            }
          }
        }
      }

      @config = Cartage::Config.new(Cartage::Config.send(:ostructify, data))

      @cartage.environment = :development
      @cartage.base_config = @config
    end

    it 'knows the subset for "development"' do
      assert_equal @config.development, @cartage.config
    end

    it 'knows the subset for the "test" plugin in "development"' do
      assert_equal @config.development.plugins.test,
        @cartage.config(for_plugin: 'test')
    end

    it 'knows the subset "test" plugin without environment' do
      assert_equal @config.plugins.test,
        @cartage.config(with_environment: false, for_plugin: :test)
    end

    it 'knows the whole config without environment' do
      assert_equal @config, @cartage.config(with_environment: false)
    end
  end

  describe '#bundle_cache' do
    def assert_bundle_cache_equal(path)
      path     = Pathname(path).join('vendor-bundle.tar.bz2')
      expected = Pathname(".").join(path)

      instance_stub Pathname, :expand_path, expected do
        yield if block_given?
        assert_equal expected, @cartage.bundle_cache
      end
    end

    it 'defaults to "tmp/vendor-bundle.tar.bz2"' do
      assert_bundle_cache_equal 'tmp/vendor-bundle.tar.bz2'
    end

    it 'can be overridden' do
      assert_bundle_cache_equal 'tmp/vendor-bundle.tar.bz2'
      assert_bundle_cache_equal 'tmpx/vendor-bundle.tar.bz2' do
        @cartage.bundle_cache 'tmpx'
      end
    end
  end

  describe '#release_hashref' do
    it 'returns the current hashref' do
      stub_backticks '12345' do
        assert_equal '12345', @cartage.release_hashref
      end
    end

    it 'saves the hashref to a file with save_to:' do
      stub_backticks '54321' do
        stub_file_open_for_write '54321' do
          @cartage.release_hashref(save_to: 'x')
        end
      end
    end
  end

  describe '#repo_url' do
    it 'returns the origin Fetch URL' do
      origin = <<-origin
* remote origin
  Fetch URL: git@github.com:KineticCafe/cartage.git
  Push  URL: git@github.com:KineticCafe/cartage.git
  HEAD branch: (not queried)
  Remote branch: (status not queried)
    master
  Local branch configured for 'git pull':
    master rebases onto remote master
  Local ref configured for 'git push' (status not queried):
    (matching) pushes to (matching)
      origin
      stub_backticks origin do
        assert_equal 'git@github.com:KineticCafe/cartage.git',
          @cartage.repo_url
      end
    end
  end

  describe '#final_tarball, #final_release_hashref' do
    before do
      @cartage.name = 'test'
      @cartage.timestamp = 'value'
      @cartage.instance_variable_set(:@root_path, Pathname('source'))
    end

    it 'sets the final tarball name correctly' do
      assert_equal Pathname('source/tmp/test-value.tar.bz2'),
        @cartage.final_tarball
    end

    it 'sets the final release hashref name correctly' do
      assert_equal Pathname('source/tmp/test-value-release-hashref.txt'),
        @cartage.final_release_hashref
    end
  end

  describe '#display' do
    it 'does not display a message if not verbose' do
      @cartage.verbose = false
      assert_silent do
        @cartage.display 'hello'
      end
    end

    it 'displays a message if verbose' do
      @cartage.verbose = true
      assert_output "hello\n" do
        @cartage.display 'hello'
      end
    end

    it 'does not display a message if verbose and quiet' do
      @cartage.verbose = true
      @cartage.quiet = true
      assert_silent do
        @cartage.display 'hello'
      end
    end
  end

  describe '#run (private)' do
    before do
      @command = %w(echo yes)
    end

    it 'displays the output if not verbose and not quiet' do
      assert_output "yes\n" do
        @cartage.send(:run, @command)
      end
    end

    it 'displays the command and output if verbose and not quiet' do
      @cartage.verbose = true
      assert_output "echo yes\nyes\n" do
        @cartage.send(:run, @command)
      end
    end

    it 'displays nothing if quiet' do
      @cartage.verbose = true
      @cartage.quiet = true
      assert_silent do
        @cartage.send(:run, @command)
      end
    end

    it 'raises an exception on error' do
      @cartage.quiet = true
      ex = assert_raises StandardError do
        @cartage.send(:run, %w(false))
      end
      assert_equal %Q(Error running 'false'), ex.message
    end
  end
end
