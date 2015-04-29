# -*- ruby encoding: utf-8 -*-

gem 'minitest'
require 'minitest/autorun'
require 'minitest/pretty_diff'
require 'minitest/focus'
require 'minitest/moar'
require 'minitest/bisect'

require 'cartage'

module Minitest::ENVStub
  def stub_env env, options = {}, *block_args, &block
    mock = lambda { |key|
      env.fetch(key) { |k|
        if options[:passthrough]
          ENV.send(:"__minitest_stub__[]", k)
        else
          nil
        end
      }
    }

    if defined? Minitest::Moar::Stubbing
      stub ENV, :[], mock, *block_args, &block
    else
      ENV.stub :[], mock, *block_args, &block
    end
  end

  def stub_cartage_repo_url value = nil, &block
    instance_stub Cartage, :repo_url,
      -> { value || 'git://host/repo-url.git' }, &block
  end

  def stub_backticks value
    Kernel.send(:alias_method, :__stub_backticks__, :`)
    Kernel.send(:define_method, :`) { |*| value }
    yield
  ensure
    Kernel.send(:undef_method, :`)
    Kernel.send(:alias_method, :`, :__stub_backticks__)
    Kernel.send(:undef_method, :__stub_backticks__)
  end

  def stub_file_open_for_write expected, string_io = StringIO.new
    mfile = File.singleton_class
    mfile.send(:alias_method, :__stub_open__, :open)

    fopen = ->(*, &block) {
      if block
        block.call(string_io)
      else
        string_io
      end
    }

    mfile.send(:define_method, :open, &fopen)
    yield
    actual = String.new(string_io.string)
  ensure
    mfile.send(:undef_method, :open)
    mfile.send(:alias_method, :open, :__stub_open__)
    mfile.send(:undef_method, :__stub_open__)
    assert_equal expected, actual
  end

  def stub_pathname_expand_path value, &block
    instance_stub Pathname, :expand_path, Pathname(value), &block
  end

  Minitest::Test.send(:include, self)
end
