# frozen_string_literal: true

require 'cartage'

##
# Provide helper methods for testing Cartage and plug-ins using Minitest.
module Cartage::Minitest
  #:nocov:

  ##
  # A helper to stub ENV lookups against an +env+ hash. If +options+ has a key
  # <tt>:passthrough</tt>, will reach for the original ENV value.
  #
  # Tested thoroughly only with Minitest::Moar::Stubbing. This helper will
  # probably be moved to a different gem in the future.
  def stub_env(env, options = {}, *block_args, &block)
    mock = lambda { |key|
      env.fetch(key) { |k|
        ENV.send(:'__minitest_stub__[]', k) if options[:passthrough]
      }
    }

    if defined?(Minitest::Moar::Stubbing)
      stub ENV, :[], mock, *block_args, &block
    else
      ENV.stub :[], mock, *block_args, &block
    end
  end

  # A helper to stub capturing shell calls (<tt>`echo true`</tt> or <tt>%x(echo
  # true)</tt>) to return +value+.
  #
  # This helper will probably be moved to a different gem in the future.
  def stub_backticks(value)
    Kernel.send(:alias_method, :__minitest_stub_backticks__, :`)
    Kernel.send(:define_method, :`) { |*| value }
    yield
  ensure
    Kernel.send(:remove_method, :`)
    Kernel.send(:alias_method, :`, :__minitest_stub_backticks__)
    Kernel.send(:remove_method, :__minitest_stub_backticks__)
  end

  # A helper to stub Cartage#repo_url to return +value+.
  def stub_cartage_repo_url(value = nil, &block)
    stub_instance_method Cartage, :repo_url, -> { value || 'git://host/repo-url.git' },
      &block
  end

  ##
  # An assertion that Pathname#write receives the +expected+ value.
  def assert_pathname_write(expected)
    string_io = StringIO.new
    stub_instance_method Pathname, :write, ->(v) { string_io.write(v) } do
      yield
      assert_equal expected, String.new(string_io.string)
    end
  end

  # A helper to stub Pathname#expand_path to return <tt>Pathname(value)</tt>.
  def stub_pathname_expand_path(value, &block)
    stub_instance_method Pathname, :expand_path, Pathname(value), &block
  end

  # A helper to define one or more methods (identified in +names+) on +target+
  # with the same +block+, which defaults to an empty callable.
  def disable_unsafe_method(target, *names, &block)
    block ||= ->(*) {}
    names.each { |name| target.define_singleton_method name, &block }
  end

  # A helper to stub Dir.chdir, which was not stubbing cleanly. This also
  # asserts that the path provided to Dir.chdir will be the +expected+ value.
  def stub_dir_chdir(expected)
    assert_equal = method(:assert_equal)

    Dir.singleton_class.send(:alias_method, :__minitest_stub_chdir__, :chdir)
    Dir.singleton_class.send(:define_method, :chdir) do |path, &block|
      assert_equal.(expected, path)
      block.call(path) if block
    end

    yield
  ensure
    Dir.singleton_class.send(:remove_method, :chdir)
    Dir.singleton_class.send(:alias_method, :chdir, :__minitest_stub_chdir__)
    Dir.singleton_class.send(:remove_method, :__minitest_stub_chdir__)
  end

  # Stubs Cartage#run and asserts that the array of commands provided are
  # matched for each call and that they are all consumed.
  def stub_cartage_run(*expected)
    expected = [ expected ].flatten(1)
    stub_instance_method Cartage, :run, ->(v) { assert_equal expected.shift, v } do
      yield
    end
    assert_empty expected
  end

  #:nocov:

  private

  # Ripped and slightly modified from minitest-stub-any-instance.
  def stub_instance_method(klass, name, val_or_callable, &block)
    if defined?(::Minitest::Moar::Stubbing)
      instance_stub klass, name, val_or_callable, &block
    elsif defined?(::Minitest::StubAnyInstance)
      klass.stub_any_instance(name, val_or_callable, &block)
    else
      begin
        new_name = "__minitest_stub_instance_method__#{name}"
        owns_method = instance_method(name).owner == klass
        klass.class_eval do
          alias_method new_name, name if owns_method

          define_method(name) do |*args|
            if val_or_callable.respond_to?(:call)
              instance_exec(*args, &val_or_callable)
            else
              val_or_callable
            end
          end
        end

        yield
      ensure
        klass.class_eval do
          remove_method name
          if owns_method
            alias_method name, new_name
            remove_method new_name
          end
        end
      end
    end
  end

  Minitest::Test.send(:include, self)
end
