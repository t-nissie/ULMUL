# ulmul.gemspec -*-ruby-*-
# Time-stamp: <2011-04-02 17:13:06 takeshi>
# Author: Takeshi Nishimatsu
##
Gem::Specification.new do |s|
  s.autorequire       = 'lib/ulmul.rb'
  s.name              = 'ulmul'

  s.bindir            = 'bin'
  s.executables       = ['ulmul2html5', 'ulmul2xhtml', 'ulmul2latex']
  s.default_executable=  'ulmul2html5'

  s.summary           = 'ULMUL is an Ultra Lightweight Mark-Up Language'
  s.files             = Dir.glob("{html}/**/*") << 'lib/ulmul.rb' << 'test/unit/ulmul_test.rb' <<
                        'ulmul2xhtml.css' << 'favicon.ico' <<
                        'ulmul2html5.css' << 'XHTML-vs-HTML5.ja.txt' <<
                        'ChangeLog' <<
                        'README-en' << 'index.en.html' <<
                        'README-ja' << 'index.ja.html' <<
                        'Rakefile' << 'ulmul.gemspec' << 'setup.rb' <<
                        'ruby.jpg' <<
                        'hello.c' <<
                        'ulmul-slidy.js' <<
                        'ulmul-slidy.css'
  s.author            = 'Takeshi Nishimatsu'
  s.email             = 't_nissie@yahoo.co.jp'
  s.rubyforge_project = 'ulmul'
  s.homepage          = 'http://ulmul.rubyforge.org/'
  s.test_files        = ['test/unit/ulmul_test.rb']

  s.has_rdoc          = true
# s.extra_rdoc_files  = %w(README)

  s.add_dependency('math_ml', '>=0.9')
  s.add_dependency('aasm',    '>=2.2.0')
  s.add_dependency('exifr',   '>=1.0.5')

  s.description       = <<-EOF
     "ULMUL" is an original Ultra Lightweight MarkUp Language.
     ULMUL texts can be converted into HTML5 with "ulmul2html5" command
     and into XHTML with "ulmul2xhtml" command.
     TeX style equations are converted into MathML.
     ULMUL is written in Ruby.
     You can also use ulmul.rb as a library.
     Visit its project homepage http://ulmul.rubyforge.org/ .

     Use ulmul-slidy.js and ulmul-slidy.css in the ulmul package for your presentations using Firefox.
     EOF
end
