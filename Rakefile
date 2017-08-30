#! /usr/bin/env rake
# -*-Ruby-*-
# Time-stamp: <2017-08-31 06:08:40 takeshi>
# Author: Takeshi Nishimatsu
##
$LOAD_PATH.unshift('lib')

require 'rubygems'
require 'rubygems/package_task'
require 'rake/testtask'
require 'rake/clean'
require 'ulmul.rb'
require 'zlib'

spec = eval(File.read("ulmul.gemspec"))
spec.version = Ulmul::VERSION
ULMUL_PACKAGE_DIR = '..'
# RDOC_OPTS = %w(--title ulmul --line-numbers)
# spec.rdoc_options = RDOC_OPTS
# CLEAN.include('html')

desc "Build a gem for ulmul"
task :gem => [ :test ]
Gem::PackageTask.new(spec) do |g|
  g.need_tar    = true
  g.need_zip    = true
  g.package_dir = ULMUL_PACKAGE_DIR
end

task :default => [ :test ]

desc "Run the unit and functional tests"
task :test
Rake::TestTask.new do |t|
  t.libs << 'lib' << 'test'
  t.pattern = 'test/**/*_test.rb'
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

desc "Publish to SourceForge"
task :sourceforge => ["index.en.html",
                      "index.ja.html",
                      "index.var",
                      "ulmul2xhtml.css", "favicon.ico", "ruby.jpg", "hello.c"] do |t|
  t.prerequisites.each do |f|
    sh "scp #{f}          web.sourceforge.net:/home/users/t/t-/t-nissie/userweb/htdocs/ULMUL/"
  end
  sh   "scp index.en.html web.sourceforge.net:/home/users/t/t-/t-nissie/userweb/htdocs/ULMUL/index.html"
  sh   "scp dot.htaccess  web.sourceforge.net:/home/users/t/t-/t-nissie/userweb/htdocs/ULMUL/.htaccess"
end

desc "Create presentation.en.html from README-en"
file "presentation.en.html" => ["bin/ulmul2html5", "README-en", "ulmul-slidy.css", "ulmul-slidy.js", "lib/ulmul.rb"] do |t|
  sh "ruby -I lib #{t.prerequisites[0]} -n 'Takeshi Nishimatsu' -s #{t.prerequisites[2]} -s #{t.prerequisites[3]} \
      -j #{t.prerequisites[4]} -j #{t.prerequisites[5]} -m 2 -l en #{t.prerequisites[1]} > #{t.name}"
end

["en", "ja"].each{|lang|
  desc "Create index.#{lang}.html"
  file "index.#{lang}.html" => ["bin/ulmul2html5", "README-#{lang}", "ulmul2html5.css", "lib/ulmul.rb"] do |t|
    sh "ruby -I lib #{t.prerequisites[0]} -n 'Takeshi Nishimatsu' -s #{t.prerequisites[2]} -j https://cdn.rawgit.com/google/code-prettify/master/loader/run_prettify.js -l #{lang} #{t.prerequisites[1]} | \
      sed -e 's%</h1>%</h1><div class=\"navi\">[<a href=\"index.en.html\">English</a>/<a href=\"index.ja.html\">Japanese</a>]</div>%' > #{t.name}"
  end
}

desc "Create README-en.tex"
file "README-en.tex" => ["bin/ulmul2latex", "README-en", "lib/ulmul.rb", "Rakefile"] do |t|
  sh "ruby -I lib #{t.prerequisites[0]} #{t.prerequisites[1]} | sed -e 's/\(\$\)/(\\\\$)/' -e 's/\"#/\"\\\\#/' \
      -e 's/subs_/subs\\\\_/' -e 's/eim_/eim\\\\_/' -e 's/math_/math\\\\_/' -e 's/ulmul_/ulmul\\\\_/' \
      -e 's/t_nissie/t\\\\_nissie/' -e 's/\"\\\\Eq/\"$\\\\backslash$Eq/' -e 's/\"\\\\Fig/\"$\\\\backslash$Fig/' -e 's/\"\\\\Table/\"$\\\\backslash$Table/' -e 's/\"\\\\Code/\"$\\\\backslash$Code/' > #{t.name}"
end
