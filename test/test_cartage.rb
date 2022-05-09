# frozen_string_literal: true

require "minitest_config"

describe Cartage do
  let(:config) { nil }
  let(:cartage) { Cartage.new(config) }

  describe "#initialize" do
    it "loads an empty configuration when created without a config" do
      assert_equal Cartage::Config.new, cartage.config
    end
  end

  describe "#name, #name=" do
    it "defaults to #default_name" do
      stub_cartage_repo_url do
        assert_equal "repo-url", cartage.name
        assert_equal cartage.default_name, cartage.name
      end
    end

    it "can be overridden" do
      stub_cartage_repo_url do
        cartage.name = "xyz"
        assert_equal "xyz", cartage.name
      end
    end
  end

  describe "#root_path, #root_path=" do
    it "defaults to #default_root_path" do
      stub_cartage_repo_url do
        stub_backticks "/x/y/z" do
          assert_equal Pathname("/x/y/z"), cartage.root_path
          assert_equal cartage.default_root_path, cartage.root_path
        end
      end
    end

    it "can be overridden and creates a Pathname" do
      stub_cartage_repo_url do
        cartage.root_path = "/a/b/c"
        assert_equal Pathname("/a/b/c"), cartage.root_path
      end
    end

    it "expands the created Pathname" do
      stub_cartage_repo_url do
        cartage.root_path = "/a/b/../c"
        assert_equal Pathname("/a/c"), cartage.root_path
      end
    end
  end

  describe "#timestamp, #timestamp=" do
    it 'defaults to #now.utc.strftime("%Y%m%d%H%M%S")' do
      stub Time, :now, -> { Time.new(2014, 12, 31, 23, 59, 59, "+00:00") } do
        assert_equal "20141231235959", cartage.timestamp
        assert_equal cartage.default_timestamp, cartage.timestamp
      end
    end

    it "does no validation of assigned values" do
      cartage.timestamp = "not a timestamp"
      assert_equal "not a timestamp", cartage.timestamp
    end
  end

  describe "#target, #target=" do
    it "defaults to tmp/ as a Pathname" do
      assert_equal Pathname("tmp"), cartage.target
      assert_equal cartage.default_target, cartage.target
    end

    it "it converts the assigned value into a pathname" do
      cartage.target = "/a/b/c"
      assert_equal Pathname("/a/b/c"), cartage.target
    end
  end

  describe "#compression, #compression=" do
    it "defaults to :bzip2" do
      assert_equal :bzip2, cartage.compression
    end

    it "accepts bzip2, none, and gzip as valid values" do
      candidates = %i[bzip2 none gzip]
      candidates += candidates.map(&:to_s)
      candidates.each { |candidate|
        cartage.compression = candidate
        assert_equal candidate, cartage.compression
      }
    end

    it "fails if given an unknown type" do
      assert_raises_with_message ArgumentError, "Invalid compression type nil" do
        cartage.compression = nil
      end
      assert_raises_with_message ArgumentError, "Invalid compression type 3" do
        cartage.compression = 3
      end
      assert_raises_with_message ArgumentError, 'Invalid compression type "foo"' do
        cartage.compression = "foo"
      end
    end

    it "affects #tar_compression_extension" do
      assert_equal ".bz2", cartage.tar_compression_extension

      cartage.compression = "none"
      assert_equal "", cartage.tar_compression_extension

      cartage.compression = "gzip"
      assert_equal ".gz", cartage.tar_compression_extension
    end

    it "affects #tar_compression_flag" do
      assert_equal "j", cartage.tar_compression_flag

      cartage.compression = "none"
      assert_equal "", cartage.tar_compression_flag

      cartage.compression = "gzip"
      assert_equal "z", cartage.tar_compression_flag
    end
  end

  describe "#dependency_cache, #dependency_cache_path, #dependency_cache_path=" do
    it "defaults to #tmp_path{,/dependency-cache.tar.bz2}" do
      assert_equal cartage.tmp_path, cartage.dependency_cache_path
      assert_equal cartage.tmp_path.join("dependency-cache.tar.bz2"),
        cartage.dependency_cache
    end

    it "is affected by the compression setting" do
      cartage.compression = "none"
      assert_equal cartage.tmp_path.join("dependency-cache.tar"),
        cartage.dependency_cache

      cartage.compression = "gzip"
      assert_equal cartage.tmp_path.join("dependency-cache.tar.gz"),
        cartage.dependency_cache
    end

    it "becomes a Pathname" do
      cartage.dependency_cache_path = "foo"
      assert_equal Pathname("foo").expand_path, cartage.dependency_cache_path
      assert_equal Pathname("foo/dependency-cache.tar.bz2").expand_path,
        cartage.dependency_cache
    end
  end

  describe "#config" do
    let(:data) {
      {
        release_hashref: "12345",
        x: 1,
        plugins: {
          test: {
            x: 2
          }
        },
        commands: {
          test: {
            x: 3
          }
        }
      }
    }
    let(:config) { Cartage::Config.new(Cartage::Config.send(:ostructify, data)) }

    it 'knows the plugin "test"' do
      assert_equal config.plugins.test, cartage.config(for_plugin: :test)
    end

    it 'knows the command "test"' do
      assert_equal config.commands.test, cartage.config(for_command: :test)
    end

    it "knows the whole config" do
      assert_equal config, cartage.config
    end

    it "fails with an error when asking for plugin and command together" do
      exception = assert_raises ArgumentError do
        cartage.config(for_plugin: :test, for_command: :test)
      end
      assert_match(/Cannot get config/, exception.message)
    end
  end

  describe "#dependency_cache" do
    def assert_dependency_cache_equal(path)
      yield if block_given?
      assert_equal Pathname(".").join(path).expand_path, cartage.dependency_cache
    end

    it 'defaults to "tmp/dependency-cache.tar.bz2"' do
      assert_dependency_cache_equal "tmp/dependency-cache.tar.bz2"
    end

    it "can be overridden through #dependency_cache_path=" do
      assert_dependency_cache_equal "tmp/dependency-cache.tar.bz2"
      assert_dependency_cache_equal "tmpx/dependency-cache.tar.bz2" do
        cartage.dependency_cache_path = "tmpx"
      end
    end
  end

  describe "#release_hashref" do
    it "returns the current hashref" do
      stub_cartage_repo_url do
        stub_backticks "12345" do
          assert_equal "12345", cartage.release_hashref
        end
      end
    end
  end

  describe "#repo_url" do
    it "returns the origin Fetch URL" do
      origin = <<~ORIGIN
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
      ORIGIN
      stub_backticks origin do
        assert_equal "git@github.com:KineticCafe/cartage.git",
          cartage.repo_url
      end
    end
  end

  describe "computed paths" do
    before do
      cartage.root_path = "/a/b/c"
      cartage.name = "test"
      cartage.timestamp = "value"
    end

    it "#tmp_path is #root_path/tmp" do
      assert_equal Pathname("/a/b/c/tmp"), cartage.tmp_path
    end

    it "#work_path is #tmp_path/#name" do
      assert_equal Pathname("/a/b/c/tmp/test"), cartage.work_path
    end

    it "#final_name is #tmp_path/#name-#timestamp" do
      assert_equal Pathname("/a/b/c/tmp/test-value"), cartage.final_name
    end

    # it '#build_tarball.final_tarball is #final_name.tar#compression_extension' do
    #   assert_equal Pathname('/a/b/c/tmp/test-value.tar.bz2'),
    #     cartage.build_tarball.final_tarball
    #
    #   cartage.compression = 'none'
    #   assert_equal Pathname('/a/b/c/tmp/test-value.tar'),
    #     cartage.build_tarball.final_tarball
    #
    #   cartage.compression = 'gzip'
    #   assert_equal Pathname('/a/b/c/tmp/test-value.tar.gz'),
    #     cartage.build_tarball.final_tarball
    # end

    it "#final_release_metadata_json is #final_name-release-metadata.json" do
      assert_equal Pathname("/a/b/c/tmp/test-value-release-metadata.json"),
        cartage.final_release_metadata_json
    end
  end

  describe "#display" do
    it "does not display a message if not verbose" do
      cartage.verbose = false
      assert_silent do
        cartage.display "hello"
      end
    end

    it "displays a message if verbose" do
      cartage.verbose = true
      assert_output "hello\n" do
        cartage.display "hello"
      end
    end

    it "does not display a message if verbose and quiet" do
      cartage.verbose = true
      cartage.quiet = true
      assert_silent do
        cartage.display "hello"
      end
    end
  end

  describe "#run" do
    before do
      @command = %w[echo yes]
    end

    it "displays the output if not verbose and not quiet" do
      assert_output "yes\n" do
        cartage.send(:run, @command)
      end
    end

    it "displays the command and output if verbose and not quiet" do
      cartage.verbose = true
      assert_output "echo yes\nyes\n" do
        cartage.send(:run, @command)
      end
    end

    it "displays nothing if quiet" do
      cartage.verbose = true
      cartage.quiet = true
      assert_silent do
        cartage.send(:run, @command)
      end
    end

    it "raises an exception on error" do
      cartage.quiet = true
      ex = assert_raises StandardError do
        cartage.send(:run, %w[false])
      end
      assert_equal "Error running 'false'", ex.message
    end
  end

  describe "#release_metadata" do
    it "has the structure we want" do
      stub_cartage_repo_url do
        cartage.send(:release_hashref=, "12345")
        cartage.timestamp = 3

        expected = {
          package: {
            name: "repo-url",
            repo: {
              type: "git",
              url: "git://host/repo-url.git"
            },
            hashref: "12345",
            timestamp: 3
          }
        }

        assert_equal expected, cartage.release_metadata
      end
    end
  end

  describe "#build_package" do
    def disable_unsafe_method(*names, &block)
      block ||= -> {}
      names.each { |name| cartage.define_singleton_method name, &block }
    end

    before do
      disable_unsafe_method :prepare_work_area, :restore_modified_files,
        :save_release_metadata, :extract_dependency_cache
      disable_unsafe_method :create_dependency_cache, &->(_) {}
    end

    it "requests :vendor_dependencies and :vendor_dependencies#path" do
      disable_unsafe_method :request_build_package

      verify_request = ->(f) { assert_equal :vendor_dependencies, f }
      verify_request_map = ->(f, m) {
        assert_equal :vendor_dependencies, f
        assert_equal :path, m
        []
      }

      instance_stub Cartage::Plugins, :request, verify_request do
        instance_stub Cartage::Plugins, :request_map, verify_request_map do
          cartage.build_package
        end
      end
    end

    it "requests :pre_build_package, :build_package, and :post_build_package" do
      disable_unsafe_method :vendor_dependencies

      requests = %i[pre_build_package build_package post_build_package]

      verify_request = ->(f) { assert_equal requests.shift, f }

      instance_stub Cartage::Plugins, :request, verify_request do
        cartage.build_package
      end

      assert_empty requests
    end
  end
end
