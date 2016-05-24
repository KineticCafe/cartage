# frozen_string_literal: true

require 'minitest_config'

describe Cartage::Plugin do
  let(:config) { Cartage::Config.load(:default) }
  let(:cartage) { Cartage.new(config) }
  let(:plugin) { Cartage::Plugin::Test }
  let(:instance) { plugin.new(cartage) }

  it 'cannot be instantiated without being subclassed' do
    assert_raises_with_message NotImplementedError, 'not a subclass' do
      Cartage::Plugin.new(cartage)
    end
  end

  class Cartage::Plugin::Test < ::Cartage::Plugin
    def test
      'test'
    end
  end

  describe Cartage::Plugin::Test do
    it 'is enabled by default' do
      assert_true instance.enabled?
      assert_false instance.disabled?
    end

    it 'can be disabled by configuration' do
      contents = {
        plugins: {
          test: {
            disabled: true
          }
        }
      }.to_yaml

      config = instance_stub Pathname, :read, -> { contents } do
        instance_stub Pathname, :exist?, -> { true } do
          Cartage::Config.load('foo')
        end
      end

      cartage = Cartage.new(config)
      assert_false cartage.test.enabled?
      assert_true cartage.test.disabled?
    end

    it 'has its configured feature offers' do
      assert_true instance.offer?(:test)
      assert_false instance.offer?(:other)
    end

    it 'is named based on the class' do
      assert_equal 'test', instance.plugin_name
      assert_equal 'test', plugin.plugin_name
    end
  end

  describe Cartage::Plugins do
    let(:manifest) { Cartage::Manifest.new(cartage) }
    let(:subject) { Cartage::Plugins.new.tap { |c| c.add(instance, manifest) } }

    it '#enabled returns all enabled plugins' do
      instance.define_singleton_method(:disabled?, -> { true })
      assert_equal 1, subject.enabled.count
    end

    it '#request executes the named feature on found plug-ins' do
      instance_stub Cartage::Plugin::Test, :test, -> {} do
        subject.request(:test)
      end

      assert_instance_called Cartage::Plugin::Test, :test, 1
    end

    it '#request_map maps the named feature on found plug-ins' do
      instance_stub Cartage::Plugin::Test, :test, -> { 'TEST' } do
        assert_equal %w(TEST), subject.request_map(:test)
      end

      assert_instance_called Cartage::Plugin::Test, :test, 1
    end
  end
end
