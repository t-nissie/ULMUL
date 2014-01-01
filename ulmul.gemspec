# ulmul.gemspec -*-ruby-*-
# Time-stamp: <2014-01-01 15:06:13 takeshi>
# Author: Takeshi Nishimatsu
##
Gem::Specification.new do |s|
  s.autorequire       = 'lib/ulmul.rb'
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
  s.rubyforge_project = 'ulmul'
  s.homepage          = 'http://ulmul.rubyforge.org/'
  s.test_files        = ['test/unit/ulmul_test.rb']

  s.has_rdoc          = true
# s.extra_rdoc_files  = %w(README)

  s.add_dependency('math_ml', '>=0.14')
  s.add_dependency('aasm',    '>=3.0.25')
  s.add_dependency('exifr',   '>=1.1.3')

  s.description       = <<-EOF
     "ULMUL" is an original Ultra Lightweight MarkUp Language.
     ULMUL texts can be converted into HTML5 with "ulmul2html5" command
     and into LaTeX with "ulmul2latex" command.
     TeX style equations are converted into MathML.
     ULMUL is written in Ruby.
     "ulmul2mathjax" convert ULMUL texts into MathJax style HTML files.
     You can also use ulmul.rb as a library.
     Visit its project homepage http://ulmul.rubyforge.org/ .
     Please use ulmul-slidy.js and ulmul-slidy.css in the
     ulmul package for your presentations using Firefox.
     EOF
end
