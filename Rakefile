# frozen_string_literal: true

require "rubygems"
require "hoe"
require "rake/clean"

Hoe.plugin :doofus
Hoe.plugin :email unless ENV["CI"] || ENV["TRAVIS"]
Hoe.plugin :gemspec2
Hoe.plugin :git
Hoe.plugin :minitest
Hoe.plugin :rubygems
Hoe.plugin :travis

spec = Hoe.spec "cartage" do
  developer("Austin Ziegler", "aziegler@kineticcafe.com")
  developer("Kinetic Cafe", "dev@kineticcafe.com")

  self.history_file = "History.md"
  self.readme_file = "README.rdoc"
  self.post_install_message = <<~EOS
    This is the last release of cartage. It's been a fun ride, but Docker-
    based images are our future at Kinetic Commerce. There is one feature
    that remains useful, the release-metadata output. We have created a
    new, more extensible format for which we will be creating a gem to
    manage this. One example of the implementation can be found at:
    
      https://github.com/KineticCafe/release-metadata-ts
    
    We will also be replacing `cartage-rack` with a new gem supporting
    this new format.
  EOS

  license "MIT"

  spec_extras[:metadata] = ->(val) { val["rubygems_mfa_required"] = "true" }

  extra_deps << ["gli", "~> 2.13"]

  extra_dev_deps << ["rake", ">= 10.0"]
  extra_dev_deps << ["rdoc", "~> 6.4"]
  extra_dev_deps << ["hoe-doofus", "~> 1.0"]
  extra_dev_deps << ["hoe-gemspec2", "~> 1.1"]
  extra_dev_deps << ["hoe-git", "~> 1.5"]
  extra_dev_deps << ["hoe-travis", "~> 1.2"]
  extra_dev_deps << ["minitest", "~> 5.4"]
  extra_dev_deps << ["minitest-autotest", "~> 1.0"]
  extra_dev_deps << ["minitest-bisect", "~> 1.2"]
  extra_dev_deps << ["minitest-bonus-assertions", "~> 3.0"]
  extra_dev_deps << ["minitest-focus", "~> 1.1"]
  extra_dev_deps << ["minitest-moar", "~> 0.0"]
  extra_dev_deps << ["minitest-pretty_diff", "~> 0.1"]
  extra_dev_deps << ["simplecov", "~> 0.7"]
end

ENV["RUBYOPT"] = "-W0"

module Hoe::Publish # :nodoc:
  alias_method :__make_rdoc_cmd__cartage__, :make_rdoc_cmd

  def make_rdoc_cmd(*extra_args) # :nodoc:
    spec.extra_rdoc_files.delete_if { |f| f == "Manifest.txt" }
    __make_rdoc_cmd__cartage__(*extra_args)
  end
end

if File.exist?(".simplecov-prelude.rb")
  namespace :test do
    task :coverage do
      spec.test_prelude = 'load ".simplecov-prelude.rb"'
      Rake::Task["test"].execute
    end

    CLOBBER << "coverage"
  end
end

CLOBBER << "tmp"
