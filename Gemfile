# frozen_string_literal: true

# NOTE: This file is not the canonical source of dependencies. Edit the
# Rakefile, instead.

source "https://rubygems.org/"

# Specify your gem's dependencies in cartage.gemspec
gemspec

if ENV["LOCAL_DEV"]
  group :local_development do
    gem "cartage-s3", path: "../cartage-s3"
    gem "cartage-bundler", path: "../cartage-bundler"
    gem "cartage-remote", path: "../cartage-remote"

    gem "byebug", platforms: :mri
    gem "pry"
  end
end
