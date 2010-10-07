# ulmul_test.rb -*-ruby-*-
# Time-stamp: <2010-10-07 21:29:34 takeshi>
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

  def test_method_html
    assert(Ulmul.method_defined?(:html))
  end

  def test_singleton_new
    u = Ulmul.new(2..3,'ulmul2html5')
    assert_instance_of(Ulmul, u)
  end

end
