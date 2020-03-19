# frozen_string_literal: true

Cartage::CLI.extend do
  desc 'Create a release_metadata.json file in the current directory.'
  command %w(metadata) do |metadata|
    metadata.action do |_global, _options, _args|
      cartage.save_release_metadata(local: true)
    end
  end
end
