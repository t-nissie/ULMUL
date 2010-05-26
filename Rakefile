#! /usr/bin/env rake
# -*-Ruby-*-
# Time-stamp: <2010-05-26 17:48:08 takeshi>
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
                    "index.var",
                    "ulmul2xhtml.css", "favicon.ico", "ruby.jpg"] do |t|
  t.prerequisites.each do |f|
    sh "scp #{f}          t-nissie@rubyforge.org:/var/www/gforge-projects/ulmul/"
  end
  sh   "scp index.en.html t-nissie@rubyforge.org:/var/www/gforge-projects/ulmul/index.html"
  sh   "scp dot.htaccess  t-nissie@rubyforge.org:/var/www/gforge-projects/ulmul/.htaccess"
end

desc "Create presentation.en.xhtml from README-en"
file "presentation.en.xhtml" => ["bin/ulmul2xhtml", "ulmul-slidy.css", "README-en",
                                                    "ulmul-slidy.js", "lib/ulmul.rb"] do |t|
  sh "ruby -I lib #{t.prerequisites[0]} -n 'Takeshi Nishimatsu' -s #{t.prerequisites[1]} -j #{t.prerequisites[3]} -l en #{t.prerequisites[2]} > #{t.name}"
end

desc "Create index.en.html"
file "index.en.html" => ["bin/ulmul2xhtml", "ulmul2xhtml.css", "README-en", "lib/ulmul.rb"] do |t|
  sh "ruby -I lib #{t.prerequisites[0]} -n 'Takeshi Nishimatsu' -l en #{t.prerequisites[2]} | sed -e 's%</h1>%</h1><div class=\"navi\">[<a href=\"index.en.html\">English</a>/<a href=\"index.ja.html\">Japanese</a>]</div>%' > #{t.name}"
end

desc "Create index.ja.html"
file "index.ja.html" => ["bin/ulmul2xhtml", "ulmul2xhtml.css", "README-ja", "lib/ulmul.rb"] do |t|
  sh "ruby -I lib #{t.prerequisites[0]} -n 'Takeshi Nishimatsu' -l ja #{t.prerequisites[2]} | sed -e 's%</h1>%</h1><div class=\"navi\">[<a href=\"index.en.html\">English</a>/<a href=\"index.ja.html\">Japanese</a>]</div>%' > #{t.name}"
end
