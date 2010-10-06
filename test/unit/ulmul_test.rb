# ulmul_test.rb -*-ruby-*-
# Time-stamp: <2010-10-06 18:43:08 takeshi>
# Author: Takeshi NISHIMATSU
##
require 'test_helper'

class TestISI < Test::Unit::TestCase
  def test_exist_Ulmul
    assert_instance_of(Class, Ulmul)
  end
end
