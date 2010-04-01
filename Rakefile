#! /usr/bin/env rake
# -*-Ruby-*-
# Time-stamp: <2010-04-01 08:37:35 takeshi>
# Author: Takeshi Nishimatsu
##
$LOAD_PATH.unshift('lib')

require 'rubygems'
require 'rake/gempackagetask'
require 'rake/testtask'
require 'rake/clean'
require 'ulmul.rb'
require 'archive/tar/minitar'
require 'zlib'

spec = eval(File.read("ulmul.gemspec"))
spec.version = Ulmul::VERSION
ULMUL_PACKAGE_DIR = '..'
# RDOC_OPTS = %w(--title ulmul --line-numbers)
# spec.rdoc_options = RDOC_OPTS
# CLEAN.include('html')

desc "Build a gem for ulmul"
task :gem => [ :test ]
Rake::GemPackageTask.new(spec) do |g|
  g.need_tar    = true
  g.need_zip    = true
  g.package_dir = ULMUL_PACKAGE_DIR
end

task :default => [ :test ]

desc "Run the unit and functional tests"
task :test
Rake::TestTask.new do |t|
  t.test_files = FileList['tests/*.rb']
  t.verbose = true
end

# Rake::RDocTask.new do |rdoc|
#   rdoc.rdoc_dir = 'html'
#   rdoc.options = RDOC_OPTS
#   if ENV['DOC_FILES']
#     rdoc.rdoc_files.include(ENV['DOC_FILES'].split(/,\s*/))
#   else
#     rdoc.rdoc_files.include('lib/**/*.rb')
#   end
# end

desc "Publish to RubyForge"
task :rubyforge => ["index.en.html",
                    "index.ja.html",
                    "style.css", "favicon.ico", "ruby.jpg"] do |t|
  t.prerequisites.each do |f|
    sh "scp #{f} t-nissie@rubyforge.org:/var/www/gforge-projects/ulmul/"
  end
end

desc "Create index.en.html"
file "index.en.html" => ["bin/ulmul2xhtml", "ulmul2xhtml.css", "README-en", "lib/ulmul.rb"] do |t|
  sh "ruby -I lib #{t.prerequisites[0]} -n 'Takeshi Nishimatsu' -l en #{t.prerequisites[2]} > #{t.name}"
end

desc "Create index.ja.html"
file "index.ja.html" => ["bin/ulmul2xhtml", "ulmul2xhtml.css", "README-ja", "lib/ulmul.rb"] do |t|
  sh "ruby -I lib #{t.prerequisites[0]} -n 'Takeshi Nishimatsu' -l ja #{t.prerequisites[2]} > #{t.name}"
end
