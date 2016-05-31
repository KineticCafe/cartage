# frozen_string_literal: true

require 'minitest_config'

describe 'Cartage::Manifest' do
  let(:cartage) { Cartage.new }
  let(:manifest) { cartage.manifest }
  let(:manifest_contents) { %w(bin/build bin/cartage lib/cartage.rb spec/cartage.rb) }
  let(:expected_tmpfile) { %W(foo/bin/build\n foo/bin/cartage\n foo/lib/cartage.rb\n) }

  before do
    cartage
  end

  def stub_slugignore_file(exists: true, contents: nil)
    ignore_file = manifest.send(:slugignore_file)
    stub ignore_file, :exist?, -> { exists } do
      if contents
        stub ignore_file, :readlines, -> { contents } do
          yield
        end
      else
        yield
      end
    end
  end

  def stub_ignore_file(exists: true, contents: nil)
    ignore_file = manifest.send(:ignore_file)
    stub ignore_file, :exist?, -> { exists } do
      if contents
        stub ignore_file, :readlines, -> { contents } do
          yield ignore_file
        end
      else
        yield ignore_file
      end
    end
  end

  def stub_manifest_file(exists: true, contents: nil)
    manifest_file = manifest.send(:manifest_file)
    stub manifest_file, :exist?, -> { exists } do
      if contents
        stub manifest_file, :readlines, -> { contents } do
          yield
        end
      else
        yield
      end
    end
  end

  describe '#resolve' do
    it 'fails if there is no manifest_file' do
      stub_manifest_file exists: false do
        ex = assert_raises Cartage::Manifest::MissingError do
          manifest.resolve
        end
        assert_match(/cannot create/, ex.message)
      end
    end

    it 'fails if there is no block given' do
      stub_manifest_file do
        assert_raises_with_message ArgumentError, 'A block is required.' do
          manifest.resolve
        end
      end
    end

    it 'fails if the manifest is empty' do
      stub_manifest_file contents: [] do
        assert_raises_with_message RuntimeError, 'Manifest.txt is empty.' do
          manifest.resolve {}
        end
      end
    end

    it 'yields the name of a tempfile with the manifest contents' do
      stub_ignore_file contents: [] do
        stub_manifest_file contents: manifest_contents do
          manifest.resolve(Pathname('foo')) { |name|
            assert_match(/Manifest\./, name)
            assert_equal (expected_tmpfile << "foo/spec/cartage.rb\n"),
              Pathname(name).readlines
          }
        end
      end
    end

    it 'prunes out ignored files from a specified cartignore' do
      stub_ignore_file contents: %w(spec/) do
        stub_manifest_file contents: manifest_contents do
          manifest.resolve(Pathname('foo')) { |name|
            assert_equal expected_tmpfile, Pathname(name).readlines
          }
        end
      end
    end

    it 'prunes out ignored files from a specified slugignore' do
      stub_ignore_file exists: false do
        stub_slugignore_file contents: %w(spec/) do
          stub_manifest_file contents: manifest_contents do
            manifest.resolve(Pathname('foo')) { |name|
              assert_equal expected_tmpfile, Pathname(name).readlines
            }
          end
        end
      end
    end

    it 'prunes out ignored files from the default cartignore' do
      stub_ignore_file exists: false do
        stub_slugignore_file exists: false do
          stub_manifest_file contents: manifest_contents do
            manifest.resolve(Pathname('foo')) { |name|
              assert_equal expected_tmpfile.reject { |v| v =~ /build/ },
                Pathname(name).readlines
            }
          end
        end
      end
    end

    it 'prunes out ignored files with a leading slash' do
      stub_ignore_file contents: %w(/spec) do
        stub_manifest_file contents: manifest_contents do
          manifest.resolve(Pathname('foo')) { |name|
            assert_equal expected_tmpfile, Pathname(name).readlines
          }
        end
      end
    end
  end

  describe '#generate' do
    it 'is created with sorted and unique filenames' do
      assert_pathname_write "a\nb\nc\n" do
        stub_backticks %w(b a a a b c).join("\n") do
          manifest.generate
        end
      end
    end
  end

  describe '#check' do
    it 'fails if there is no manifest_file' do
      stub_manifest_file exists: false do
        ex = assert_raises Cartage::Manifest::MissingError do
          manifest.check
        end
        assert_match(/cannot create/, ex.message)
      end
    end

    it 'compares the current files against the manifest' do
      begin
        sysc = ->(*args) { IO.popen(args) { |diff| puts diff.read } }

        assert_output(/^\+d/) do
          instance_stub Kernel, :system, sysc do
            stub_backticks %w(a b c).join("\n") do
              manifest.instance_variable_set(:@manifest_file, Pathname('Manifest.test'))
              manifest.generate
            end

            stub_backticks %w(a b c d).join("\n") do
              manifest.check
            end
          end
        end
      ensure
        file = manifest.send(:manifest_file)
        file.unlink if file.to_s.end_with?('Manifest.test')
      end
    end
  end

  describe '#install_default_ignore' do
    before do
      cartage.verbose = true
    end

    it 'does nothing if the ignore file exists without overwrite or merge' do
      assert_output ".cartignore already exists, skipping...\n" do
        stub_ignore_file do |ignore_file|
          stub ignore_file, :write, ->(_) {} do
            manifest.install_default_ignore
          end

          refute_instance_called ignore_file.class, :write
        end
      end
    end

    def ignore_file_writer(expected = nil)
      case expected
      when Regexp
        ->(actual) { assert_match expected, actual }
      when String
        ->(actual) { assert_equal expected, actual }
      when nil
        ->(_) {}
      end
    end

    it 'merges if mode is merge' do
      stub_ignore_file contents: %w(xyz/) do |ignore_file|
        stub ignore_file, :write, ignore_file_writer(%r{^xyz/.*vendor/bundle/$}m) do
          assert_output "Merging .cartignore...\n" do
            manifest.install_default_ignore(mode: 'merge')
          end

          assert_instance_called ignore_file.class, :write
        end
      end
    end

    it 'merges if mode is merge and ignore file is empty' do
      stub_ignore_file contents: [] do |ignore_file|
        stub ignore_file, :write, ignore_file_writer(%r{^# Some .*vendor/bundle/$}m) do
          assert_output "Merging .cartignore...\n" do
            manifest.install_default_ignore(mode: 'merge')
          end

          assert_instance_called ignore_file.class, :write
        end
      end
    end

    it 'forces when mode is force' do
      stub_ignore_file contents: %w(xyz/) do |ignore_file|
        stub ignore_file, :write, ignore_file_writer(%r{^# Some .*vendor/bundle/$}m) do
          assert_output "Creating .cartignore...\n" do
            manifest.install_default_ignore(mode: 'force')
          end

          assert_instance_called ignore_file.class, :write
        end
      end
    end
  end
end
