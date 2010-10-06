# ulmul_test.rb -*-ruby-*-
# Time-stamp: <2010-10-06 20:45:46 takeshi>
# Author: Takeshi NISHIMATSU
##
require 'rubygems'
require 'test/unit'
require 'ulmul'

class TestULMUL < Test::Unit::TestCase
  def test_exist_Ulmul
    assert_instance_of(Class, Ulmul)
  end
  def test_singleton_new
    u = Ulmul.new(2..3,'ulmul2html5')
    assert_instance_of(Ulmul, u)
  end
  def test_method_parse
    u = Ulmul.new(2..3,'ulmul2xhtml')
    assert_respond_to(u,:parse)
  end
  def test_method_html
    u = Ulmul.new(2..3,'ulmul2xhtml')
    assert_respond_to(u,:html)
  end
end
