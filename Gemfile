# frozen_string_literal: true

# NOTE: This file is not the canonical source of dependencies. Edit the
# Rakefile, instead.

source 'https://rubygems.org/'

# Specify your gem's dependencies in cartage.gemspec
gemspec

group :local_development, :test do
  gem 'cartage-s3', path: '../cartage-s3'
  gem 'cartage-bundler', path: '../cartage-bundler'
  gem 'cartage-remote', path: '../cartage-remote'

  gem 'byebug', platforms: :mri
  gem 'pry'
end if ENV['LOCAL_DEV']
