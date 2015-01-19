# ulmul.gemspec -*-ruby-*-
# Time-stamp: <2015-01-19 12:44:52 takeshi>
# Author: Takeshi Nishimatsu
##
Gem::Specification.new do |s|
  s.name              = 'ulmul'

  s.bindir            = 'bin'
  s.executables       = ['ulmul2html5', 'ulmul2xhtml', 'ulmul2latex', 'ulmul2mathjax']
  s.default_executable=  'ulmul2html5'

  s.summary           = 'ULMUL is an Ultra Lightweight Mark-Up Language'
  s.files             = ['lib/ulmul.rb', 'test/unit/ulmul_test.rb',
                        'ulmul2xhtml.css', 'favicon.ico',
                        'ulmul2html5.css', 'XHTML-vs-HTML5.ja.txt',
                        'ChangeLog',
                        'Changes',
                        'README-en', 'index.en.html',
                        'README-ja', 'index.ja.html',
                        'Rakefile', 'ulmul.gemspec', 'setup.rb',
                        'ruby.jpg',
                        'ruby.eps',
                        'ruby.obj',
                        'hello.c',
                        'ulmul-slidy.js',
                        'ulmul-slidy.css']
  s.author            = 'Takeshi Nishimatsu'
  s.email             = 't_nissie@yahoo.co.jp'
  s.license           = 'GPLv3'
  s.homepage          = 'http://t-nissie.users.sourceforge.net/ULMUL/'
  s.test_files        = ['test/unit/ulmul_test.rb']

  s.has_rdoc          = true
# s.extra_rdoc_files  = %w(README)

  s.add_dependency('math_ml', '~> 0.14')
  s.add_dependency('aasm',    '~> 4.0', '>= 4.0.8')
  s.add_dependency('exifr',   '~> 1.2', '>= 1.2.0')

  s.description       = <<-EOF
     ULMUL is an original Ultra Lightweight MarkUp Language.
     You can write TeX-style equations in ULMUL texts.
     The ULMUL texts can be converted
     into HTML5+MathML  with ulmul2html5 command,
     into HTML5+MathJax with ulmul2mathjax and
     into LaTeX with ulmul2latex.
     You can also generate Slidy presentations.
     Its library ulmul.rb is written in Ruby.
     EOF
end
