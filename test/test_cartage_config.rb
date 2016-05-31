# frozen_string_literal: true

require 'minitest_config'
require 'cartage/config'

describe Cartage::Config do
  let(:data) {
    {
      'x' => 1,
      'arr' => %w(a b c),
      'commands' => {},
      'plugins' => {
        'test' => {
          'x' => 2
        }
      }
    }
  }
  let(:odata) { Cartage::Config.send(:ostructify, data) }
  let(:config) { Cartage::Config.new(odata) }
  let(:hdata) { Marshal.load(Marshal.dump(data)) }

  describe 'load' do
    def watch_pathname_exist
      mpname = Pathname.singleton_class
      mpname.send(:define_method, :exist_tries, -> { @exist_tries ||= [] })

      Pathname.send(:alias_method, :__stub_exist__?, :exist?)
      Pathname.send(:define_method, :exist?, -> { !(self.class.exist_tries << to_s) })

      yield
    ensure
      mpname.send(:undef_method, :exist_tries)
      Pathname.send(:undef_method, :exist?)
      Pathname.send(:alias_method, :exist?, :__stub_exist__?)
      Pathname.send(:undef_method, :__stub_exist__?)
    end

    def ignore_pathname_expand_path
      Pathname.send(:alias_method, :__stub_expand_path__, :expand_path)
      Pathname.send(:define_method, :expand_path, -> { self })

      yield
    ensure
      Pathname.send(:undef_method, :expand_path)
      Pathname.send(:alias_method, :expand_path, :__stub_expand_path__)
      Pathname.send(:undef_method, :__stub_expand_path__)
    end

    it 'looks for default files when given :default' do
      watch_pathname_exist do
        ignore_pathname_expand_path do
          Cartage::Config.load(:default)
          assert_equal Cartage::Config::DEFAULT_CONFIG_FILES, Pathname.exist_tries
        end
      end
    end

    it 'fails if the file does not exist' do
      instance_stub Pathname, :exist?, -> { false } do
        assert_raises_with_message ArgumentError,
          'Configuration file foo does not exist.' do
          Cartage::Config.load('foo')
        end
      end
    end

    it 'loads the file if it exists' do
      instance_stub Pathname, :read, -> { '{ faked: true }' } do
        instance_stub Pathname, :exist?, -> { true } do
          expected = {
            faked: true,
            commands: OpenStruct.new,
            plugins: OpenStruct.new
          }
          assert_equal expected,
            Cartage::Config.load('foo').instance_variable_get(:@table)
        end
      end
    end

    it 'uses a default configuration if there is no default config file' do
      expected = {
        commands: OpenStruct.new,
        plugins: OpenStruct.new
      }
      assert_equal expected,
        Cartage::Config.load(:default).instance_variable_get(:@table)
    end
  end

  describe 'import' do
    it 'reads a file if it exists' do
      stub File, :exist?, ->(_) { true } do
        stub File, :read, ->(_) { 'faked' } do
          assert_equal 'faked', Cartage::Config.import('foo')
        end
      end
    end

    it 'returns nil if the file does not exist' do
      stub File, :exist?, ->(_) { false } do
        assert_nil Cartage::Config.import('foo')
      end
    end
  end

  describe '#to_h' do
    it 'completely converts a Config object to hash' do
      assert_equal hdata, config.to_h
    end
  end

  describe '#to_yaml' do
    it 'overrides the OpenStruct implementation' do
      assert_equal hdata.to_yaml, config.to_yaml
    end
  end
end
