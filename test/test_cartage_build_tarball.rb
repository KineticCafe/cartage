# frozen_string_literal: true

require 'minitest_config'

describe 'Cartage::BuildTarball' do
  let(:config) {
    Cartage::Config.new(
      root_path: '/a/b/c',
      name: 'test',
      timestamp: 'value'
    )
  }
  let(:cartage) {
    Cartage.new(config)
  }
  let(:subject) { cartage.build_tarball }

  it '#build_package requests :pre_build_tarball and :post_build_tarball' do
    requests = %i(pre_build_tarball post_build_tarball)

    verify_request = ->(f) { assert_equal requests.shift, f }
    verify_run = ->(c) {
      assert_equal [
        'tar',
        'cfj',
        '/a/b/c/tmp/test-value.tar.bz2',
        '-C',
        '/a/b/c/tmp',
        'test'
      ], c
    }

    instance_stub Cartage::Plugins, :request, verify_request do
      instance_stub Cartage, :run, verify_run do
        subject.build_package
      end
    end

    assert_empty requests
  end

  describe '#package_name is dependent on Cartage configuration' do
    it 'is .tar.bz2 when compression is :bzip2' do
      assert_equal Pathname('/a/b/c/tmp/test-value.tar.bz2'), subject.package_name
    end

    it 'is .tar when compression is :none' do
      cartage.compression = 'none'
      assert_equal Pathname('/a/b/c/tmp/test-value.tar'), subject.package_name
    end

    it 'is .tar.gz when compression is :gzip' do
      cartage.compression = 'gzip'
      assert_equal Pathname('/a/b/c/tmp/test-value.tar.gz'), subject.package_name
    end
  end
end
