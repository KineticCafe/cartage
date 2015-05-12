require 'minitest_config'
require 'cartage/plugin'
require 'cartage/command'
require 'cartage/manifest'

describe Cartage::Manifest do
  before do
    @cartage = Cartage.new
    @manifest = Cartage::Manifest.new(@cartage)
  end

  describe '#create_file_list' do
    it 'only sets unique files' do
      files = %w(a a a b c).join("\n")
      expected = %w(a b c).join("\n") + "\n"

      stub_file_open_for_write expected do
        stub_backticks files do
          @manifest.send :create_file_list, 'x'
        end
      end
    end
  end
end
