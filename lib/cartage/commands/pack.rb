# frozen_string_literal: true

Cartage::CLI.extend do
  desc "Create a package with Cartage based on the Manifest."
  command %w[pack build] do |pack|
    pack.desc "Do not check the status of the Manifest file before packaging."
    pack.switch "skip-check", negatable: false

    pack.action do |_global, options, _args|
      unless options["skip-check"] || cartage.manifest.check
        puts
        fail Cartage::CLI::CustomExit.new "Manifest.txt is not up-to-date.",
          $?.exitstatus
      end
      cartage.build_package
    end
  end
end
