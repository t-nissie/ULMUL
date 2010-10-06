# test_helper.rb -*-ruby-*-
# test_helper.rb was copied from aasm-2.2.0 http://rubygems.org/gems/aasm/ by Scott Barron
# Time-stamp: <2010-10-06 19:25:34 takeshi>
# Modified by: Takeshi NISHIMATSU
##
# require 'ostruct'
require 'rubygems'

begin
  gem 'minitest'
rescue Gem::LoadError
  puts 'minitest gem not found'
end

begin
  require 'minitest/autorun'
  puts 'using minitest'
rescue LoadError
  require 'test/unit'
  puts 'using test/unit'
end

# require 'rr'
# require 'shoulda'
#
# class Test::Unit::TestCase
#   include RR::Adapters::TestUnit
# end

begin
  require 'ruby-debug'
  Debugger.start
rescue LoadError
end

# $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
# $LOAD_PATH.unshift(File.dirname(__FILE__))

require 'ulmul'
