#! /usr/bin/env ruby
# isi_test.rb -*-ruby-*-
# Time-stamp: <2008-01-01 17:43:26 takeshi>
# Author: Takeshi NISHIMATSU
##
require 'rubygems'
require 'rubyunit'
require 'ulmul'

class TestISI < RUNIT::TestCase
  def test_exist_Ulmul
    assert_instance_of(Class, Ulmul)
  end
end
