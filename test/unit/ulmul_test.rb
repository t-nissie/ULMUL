# ulmul_test.rb -*-ruby-*-
# Time-stamp: <2011-04-02 17:10:52 takeshi>
# Author: Takeshi NISHIMATSU
##
require 'rubygems'
require 'test/unit'
require 'ulmul'
class TestULMUL < Test::Unit::TestCase
  def test_exist_Ulmul
    assert_instance_of(Class, Ulmul)
  end

  def test_method_parse
    assert(Ulmul.method_defined?(:parse))
  end

  def test_singleton_new
    u = Ulmul.new()
    assert_instance_of(Ulmul, u)
  end
end
