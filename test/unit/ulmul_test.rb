# ulmul_test.rb -*-ruby-*-
# Time-stamp: <2010-10-06 20:14:21 t-nissie>
# Author: Takeshi NISHIMATSU
##
require 'rubygems'
require 'test/unit'
require 'ulmul'

class TestISI < Test::Unit::TestCase
  def test_exist_Ulmul
    assert_instance_of(Class, Ulmul)
  end
end
