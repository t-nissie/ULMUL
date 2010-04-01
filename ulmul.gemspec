# ulmul.gemspec -*-ruby-*-
# Time-stamp: <2010-04-01 15:25:05 takeshi>
# Author: Takeshi Nishimatsu
##
Gem::Specification.new do |s|
  s.autorequire       = 'lib/ulmul.rb'
  s.name              = 'ulmul'

  s.bindir            = 'bin'
  s.executables       = ['ulmul2html5', 'ulmul2xhtml']
  s.default_executable=  'ulmul2html5'

  s.summary           = 'ULMUL is an Ultra Lightweight Mark-Up Language'
  s.files             = Dir.glob("{html}/**/*") << 'lib/ulmul.rb' << 'tests/ulmul_test.rb' <<
                        'ulmul2xhtml.css' << 'favicon.ico' <<
                        'ulmul2html5.css' << 'XHTML-vs-HTML5.ja.txt' <<
                        'ChangeLog' <<
                        'README-en' << 'index.en.html' <<
                        'README-ja' << 'index.ja.html' <<
                        'Rakefile' << 'ulmul.gemspec' << 'setup.rb' <<
                        'ruby.jpg' << 'slidy.js' << 'ulmul-slidy.css'
  s.author            = 'Takeshi Nishimatsu'
  s.email             = 't-nissie@imr.tohoku.ac.jp'
  s.rubyforge_project = 'ulmul'
  s.homepage          = 'http://ulmul.rubyforge.org/'
  s.test_files        = ['tests/ulmul_test.rb']

  s.has_rdoc          = true
# s.extra_rdoc_files  = %w(README)

  s.add_dependency('mathml', '>=0.8.1')

  s.description       = <<-EOF
     ULMUL is an Ultra Lightweight Mark-Up Language.
     EOF
end
