# ulmul.gemspec -*-ruby-*-
# Time-stamp: <2010-02-12 00:41:51 takeshi>
# Author: Takeshi Nishimatsu
##
Gem::Specification.new do |s|
  s.autorequire       = 'lib/ulmul.rb'
  s.name              = 'ulmul'

  s.bindir            = 'bin'
  s.executables       = ['ulmul2html']
  s.default_executable=  'ulmul2html'

  s.summary           = 'ULMUL is an Ultra Lightweight Mark-Up Language'
  s.files             = Dir.glob("{html}/**/*") << 'lib/ulmul.rb' <<
                        'tests/ulmul_test.rb' << 'style.css' << 'favicon.ico' << 'index.html' <<
                        'ChangeLog' << 'README-en.xhtml' << 'README-ja' << 'README-ja.xhtml' <<
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
