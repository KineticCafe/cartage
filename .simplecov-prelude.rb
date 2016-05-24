require 'simplecov'

SimpleCov.start do
  command_name 'Minitest'
  add_filter '/lib/cartage/backport.rb'
  add_filter '/test/'
end

gem 'minitest'
