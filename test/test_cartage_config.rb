require 'minitest_config'
require 'cartage/config'

describe Cartage::Config do
  before do
    @data = {
      "x" => 1,
      "arr" => %w(a b c),
      "plugins" => {
        "test" => {
          "x" => 2
        }
      },
      "development" => {
        "x" => 3,
        "plugins" => {
          "test" => OpenStruct.new("x" => 4)
        }
      }
    }

    @odata = Cartage::Config.send(:ostructify, @data)
    @config = Cartage::Config.new(@odata)
    @hdata = Marshal.load(Marshal.dump(@data))
    @hdata['development']['plugins']['test'] = { "x" => 4 }
  end

  describe '#ostructify (private)' do
    it 'converts hash structures correctly' do
      expected = OpenStruct.new(x: 1)
      expected.arr = %w(a b c)
      expected.plugins = OpenStruct.new
      expected.plugins.test = OpenStruct.new(x: 2)
      expected.development = OpenStruct.new(x: 3)
      expected.development.plugins = OpenStruct.new
      expected.development.plugins.test = OpenStruct.new(x: 4)

      assert_equal expected, @odata
    end
  end

  describe '#to_h' do
    it 'completely converts a Config object to hash' do
      assert_equal @hdata, @config.to_h
    end
  end
end
