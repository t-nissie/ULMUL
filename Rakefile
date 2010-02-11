#! /usr/bin/env rake
# -*-Ruby-*-
# Time-stamp: <2010-02-12 00:40:43 takeshi>
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
spec.version = ULMUL_RB_VERSION
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
task :rubyforge => ["README-en.xhtml",
                    "README-ja.xhtml",
                    "style.css", "index.html", "favicon.ico", "ruby.jpg"] do |t|
  t.prerequisites.each do |f|
    sh "scp #{f} t-nissie@rubyforge.org:/var/www/gforge-projects/ulmul/"
  end
end

desc "Build Packages"
task :package => [ :ulmul_version_rb ]

desc "Copy lib/ulmul.rb ../ulmul-X.Y.Z.rb"
task :ulmul_version_rb do
  FileUtils.copy_file('lib/ulmul.rb', ULMUL_PACKAGE_DIR + '/ulmul-' + ULMUL_RB_VERSION + '.rb')
end

desc "Create README-en.xhtml"
file "README-en.xhtml" => ["bin/ulmul2html", "style.css", "lib/ulmul.rb"] do |t|
  sh "ruby -I lib #{t.prerequisites[0]} -c 2..3 -s #{t.prerequisites[1]} #{t.prerequisites[2]} > #{t.name}"
end

desc "Create README-ja.xhtml"
file "README-ja.xhtml" => ["bin/ulmul2html", "style.css", "README-ja"] do |t|
  sh "ruby -I lib #{t.prerequisites[0]} -c 2..3 -s #{t.prerequisites[1]} #{t.prerequisites[2]} > #{t.name}"
end
