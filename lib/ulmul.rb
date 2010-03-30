#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# ulmul.rb
# Time-stamp: <2010-03-30 22:45:09 takeshi>
# Author: Takeshi Nishimatsu
##
=begin
= ULMUL (ulmul.rb)
ULMUL (ulmul.rb) is a converter from Ultra Lightweight MarkUp Language to
(X)HTML. You can create HTML files, Slidy HTML files and MathML XHTML
files very easily.

The author is using ULMUL to generate his web pages.
http://loto.sourceforge.net/feram/ is converted from
http://loto.sourceforge.net/feram/README .
http://loto.sourceforge.net/feram/doc/film.xhtml is converted from 
http://loto.sourceforge.net/feram/doc/film.txt .

== Where is the homepage of ULMUL?
http://ulmul.rubyforge.org/

== Where can I download ulmul.rb?
Go to http://rubyforge.org/projects/ulmul .

== How can I install ULMUL?
There are two different ways to install ULMUL.
=== I. Conservative way; use setup.rb
ulmul-X.Y.Z.tgz package can be installed as:
  $ tar zxf ulmul-X.Y.Z.tgz
  $ cd ulmul-X.Y.Z
  $ su
  # ruby setup.rb
Note that the eimxml and mathml libraries are required.
=== II. RubyGems users can take an easy way
There is an easy way, if you are a RubyGems user:
  $ su
  # gem install ulmul
If you do not have the eimxml and mathml libraries, gem will download and install the
library automatically.

=== Files
 * ulmul.rb         Ruby script.
 * slidy.js         JavaScript for Slidy. Slightly modified from the original.
 * ulmul-slidy.css　CSS file for Slidy.  Largely modified from the original.
 * style.css        Example CSS file for normal web pages.
If you installed ULMUL with gem, you may find these files in
/usr/local/lib/ruby/gems/1.8/gems/ulmul-X.Y.Z/
or    /usr/lib/ruby/gems/1.8/gems/ulmul-X.Y.Z/ .

== How can I write a ULMUL text?
The encode of input file must be utf-8.
=== Events (each input line)
==== empty
Empty lines devide paragraphs.
==== heading
Starting with "= ", "== ", "=== ", "==== ", "===== ", and "====== ".
"= " will be used for the title.
==== asterisk
Lines starting with
 " *"
 "   *"
 "     *"
 "       *"
 "         *"
become itemize.
==== offset
Lines starting with some spaces but not asterisks become verbatim lines.
==== end
EOF or "=end" end the process.
==== ignore
Lines starting with"#" and "=begin" are ignored.
==== normal
Other lines.
=== Other rules
 * Lines after "=end" are ignored.
 * Add your substitution rules to @subs_rules.
=== Equations
Input:
 Mass $m$ can be converted into energy $E$ as
 Eq. 1
            E=mc^2.
 /Eq.

Output:

Mass $m$ can be converted into energy $E$ as
Eq. 1
            E=mc^2.
/Eq.

=== Figures
Input:
 Fig. 1 ruby.jpg
   The is a dummy figure for an example.
 /Fig.

Output:
Fig. 1 ruby.jpg
  The is a dummy figure for an example.
  Cute red logo of Ruby, isn't it?
/Fig.


== Usage
=== Examples
 % ruby ulmul.rb foo.txt
 % ruby ulmul.rb --style=style.css --name="John Smith" foo.ulmul > foo.html
 % ./ulmul.rb --style=ulmul-slidy.css --javascript=slidy.js \
   --name="Takeshi Nishimatsu" presentation.txt > presentation.xhtml
=== Command options
==== -s, --style
Specify stylesheet filename.
==== -n, --name
Specify your name for copyright notices.
==== -j, --javascript
Specify JavaScript filename.
==== -l, --language
Specify natural language. Its default is "en".
==== -c, --contents-range
Range of "Contents". Its default is "2..3".
If you do not need "Contents" at the beginning of the
output HTML file, set it 3..2.
==== --help
Show a help message.

== TODO
 * rescue syntax errors (raises) in an input file and report the
   errors as #{$FILENAME}:#{file.lineno}:...
 * Unit test, tests/ulmul_test.rb
 * @body must be XML object, not a String.
 * Tables.
 * References to figures and tables.
 * Citation.

== How can I get the latest source tree of ULMUL?

You can checkout the latest source tree of ULMUL anonymously from RubyForge with svn(1) command:

 $ svn co svn://rubyforge.org/var/svn/ulmul/ulmul/trunk ulmul

== Copying
ulmul.rb is distributed in the hope that
it will be useful, but WITHOUT ANY WARRANTY.
You can copy, modify and redistribute ulmul.rb,
but only under the conditions described in
the GNU General Public License (the "GPL").

W3C has copyrights for slidy.js and ulmul-slidy.css (originally
named slidy.css). Takeshi Nishimatsu modified them.
You can download the original package, slidy.zip, from
http://www.w3.org/Talks/Tools/Slidy/ . You can find
their licenses at http://www.w3.org/Consortium/Legal/copyright-documents
and http://www.w3.org/Consortium/Legal/copyright-software .

== Author of ULMUL
Takeshi Nishimatsu (t_nissie{at}yahoo.co.jp)

=end
require "rubygems"
require "date"
require "math_ml/string"

class String
  def apply_subs_rules(rules)
    result = self.dup
    rules.each do |ary|
      result.gsub!(ary[0],ary[1])
    end
    is_mathml = false
    while result =~ /\$(.*?)\$/
      pre=$`
      tex=Regexp.last_match[1]
      post=$'
      result = "#{pre}#{tex.to_mathml}#{post}"
      is_mathml = true
    end
    return result, is_mathml
  end
end

module Itemize
  def itemize_begin(e)
    @level_of_state = 0
  end

  def itemize_add_primitive(new_level,str)
    if new_level>@level_of_state+1
      raise 'Illegal jump of itemize level'
    elsif new_level==@level_of_state+1
      @body << "\n" << "    "*@level_of_state << "<ul>\n"
      @body <<              "    "*(new_level-1) << "  " << "<li>#{str}"
      @level_of_state = new_level
    elsif new_level==@level_of_state
      @body << "</li>\n" << "    "*(new_level-1) << "  " << "<li>#{str}"
    else
      @body << "</li>\n"
      (@level_of_state-1).downto(new_level){|i| @body << "    "*i << "</ul></li>\n"}
      @body              << "    "*(new_level-1) << "  " << "<li>#{str}"
      @level_of_state = new_level
    end
  end

  def itemize_continue_primitive(new_level,str)
    (@level_of_state-1).downto(new_level){|i| @body << "</li>\n" << "    "*i << "</ul>"}
    @body << "\n  " << "    "*(new_level-1) << "  " << str
    @level_of_state = new_level
  end

  def itemize_end(e)
    @body << "</li>\n"
    (@level_of_state-1).downto(1){|i| @body << "    "*i << "</ul></li>\n"}
    @body << "</ul>\n"
    @level_of_state = 0
  end
end

class Contents
  include Itemize
  def initialize()
    @state                 = 'itemize'
    @level_of_state        = 0
    @body                  = ''
  end
  attr_reader :body
end

class Ulmul
  VERSION = '0.3.0'
  CONTENTS_HERE="<!-- Contents -->"
  CONTENTS_RANGE_DEFAULT=2..3
  TABLE={
    'ignore'   => {'ground'    => [],
                   'itemize'   => [],
                   'verbatim'  => [],
                   'paragraph' => [],
                   'equation'  => [],
                   'figure'    => []},

    'end'      => {'ground'    => [                :heading_add],
                   'itemize'   => [  :itemize_end, :heading_add, 'ground'],
                   'verbatim'  => [ :verbatim_end, :heading_add, 'ground'],
                   'paragraph' => [:paragraph_end, :heading_add, 'ground'],
                   'equation'  => [:equation_error],
                   'figure'    => [:figure_error]},

    'heading'  => {'ground'    => [                :heading_add],
                   'itemize'   => [  :itemize_end, :heading_add, 'ground'],
                   'verbatim'  => [ :verbatim_end, :heading_add, 'ground'],
                   'paragraph' => [:paragraph_end, :heading_add, 'ground'],
                   'equation'  => [:equation_continue],
                   'figure'    => [:figure_continue]},

    'asterisk' => {'ground'    => [:itemize_begin, 'itemize', :itemize_add],
                   'itemize'   => [                           :itemize_add],
                   'verbatim'  => [                          :verbatim_add],
                   'paragraph' => [:paragraph_end,
                                   :itemize_begin, 'itemize', :itemize_add],
                   'equation'  => [:equation_continue],
                   'figure'    => [:figure_continue]},

    'offset'   => {'ground'    => [:verbatim_begin, 'verbatim', :verbatim_add],
                   'itemize'   => [:itemize_continue],
                   'verbatim'  => [                             :verbatim_add],
                   'paragraph' => [:paragraph_end,
                                   :verbatim_begin, 'verbatim', :verbatim_add],
                   'equation'  => [:equation_continue],
                   'figure'    => [:figure_continue]},

    'empty'    => {'ground'    => [],
                   'itemize'   => [:itemize_end, 'ground'],
                   'verbatim'  => [:verbatim_add],
                   'paragraph' => [:paragraph_end, 'ground'],
                   'equation'  => [:equation_error],
                   'figure'    => [:figure_error]},

    'normal'   => {'ground'    => [:paragraph_begin, 'paragraph', :paragraph_add],
                   'itemize'   => [:itemize_end,
                                   :paragraph_begin, 'paragraph', :paragraph_add],
                   'verbatim'  => [:verbatim_end,
                                   :paragraph_begin, 'paragraph', :paragraph_add],
                   'paragraph' => [:paragraph_add],
                   'equation'  => [:equation_continue],
                   'figure'    => [:figure_continue]},

    'eq_begin' => {'ground'    => [:paragraph_begin, :equation_begin, 'equation'],
                   'itemize'   => [:itemize_end,
                                   :paragraph_begin, :equation_begin, 'equation'],
                   'verbatim'  => [:verbatim_end,
                                   :paragraph_begin, :equation_begin, 'equation'],
                   'paragraph' => [                  :equation_begin, 'equation'],
                   'equation'  => [:equation_error],
                   'figure'    => [:figure_error]},

    'eq_end'   => {'ground'    => [:equation_error],
                   'itemize'   => [:equation_error],
                   'verbatim'  => [:equation_error],
                   'paragraph' => [:equation_error],
                   'equation'  => [:equation_end, 'paragraph'],
                   'figure'    => [:figure_error]},

    'fig_begin'=> {'ground'    => [                :figure_begin, 'figure'],
                   'itemize'   => [:itemize_end,   :figure_begin, 'figure'],
                   'verbatim'  => [:verbatim_end,  :figure_begin, 'figure'],
                   'paragraph' => [:paragraph_end, :figure_begin, 'figure'],
                   'equation'  => [:equation_error],
                   'figure'    => [:figure_error]},

    'fig_end'  => {'ground'    => [:figure_error],
                   'itemize'   => [:figure_error],
                   'verbatim'  => [:figure_error],
                   'paragraph' => [:figure_error],
                   'equation'  => [:figure_error],
                   'figure'    => [:figure_end, 'ground']}
  }

  def initialize(contents_range=CONTENTS_RANGE_DEFAULT,mode='ulmul2html5')
    @contents_range        = contents_range
    @contents              = Contents.new()
    @state                 = 'ground'
    @level_of_state        = 0
    @level_of_heading      = 0
    @i_th_heading          = 0
    @equation              = ''
    @figure_caption        = ''
    @body                  = ''
    @subs_rules            = [[/(http:\S*)(\s|$)/,  '<a href="\1">\1</a>\2'],
                              [/(https:\S*)(\s|$)/, '<a href="\1">\1</a>\2']]
    @contents.itemize_begin(nil)
    @is_mathml = false

    @mode=mode
    if @mode=='ulmul2html5'
      @figure_open  =  '<figure>'
      @figure_close = '</figure>'
      @caption_open  =  '<figcaption>'
      @caption_close = '</figcaption>'
    else
      @figure_open  =  '<div class="figure">'
      @figure_close = '</div>'
      @caption_open  =  '<div class="figcaption">'
      @caption_close = '</div>'
    end
  end
  attr_accessor :subs_rules

  def equation_begin(e)
    @is_mathml = true
  end

  def equation_continue(e)
    @equation << e.line
  end

  def equation_end(e)
    @body << @equation.to_mathml('block').to_s << "\n"
    @equation =''
  end

  def figure_begin(e)
    dummy, @figure_label, @figure_file = e.line.split
    @body << "#{@figure_open}
  <img src=\"#{@figure_file}\" alt=\"#{@figure_file}\" />
  #{@caption_open}\n"
  end

  def figure_continue(e)
    result, is_mathml = e.line.apply_subs_rules(@subs_rules)
    @figure_caption << result
    @is_mathml = @is_mathml || is_mathml
  end

  def figure_end(e)
    @body << @figure_caption << "  #{@caption_close}\n" <<  "#{@figure_close}\n"
    @figure_caption =''
  end

  def figure_error(e)
    p e
    exit 1
  end

  def verbatim_begin(e)
    @level_of_state = 0
    @body << "<pre>"
  end

  def verbatim_add(e)
    if e.event=='empty'
      @level_of_state += 1
    else
      @body << "\n"*@level_of_state << e.line[1..-1].gsub(/</,'&lt;').gsub(/>/,'&gt;')
      @level_of_state=0
    end
  end

  def verbatim_end(e)
    @body << "</pre>\n"
  end

  def paragraph_begin(e)
    @level_of_state = 0
    @body << "<p>\n"
  end

  def paragraph_add(e)
    result, is_mathml = e.line.apply_subs_rules(@subs_rules)
    @body << result
    @is_mathml = @is_mathml || is_mathml
  end

  def paragraph_end(e)
    @body << "</p>\n"
  end

  def heading_add(e)
    if /^(=+) (.*)$/ =~ e.line
      new_level=Regexp.last_match[1].length
      str=Regexp.last_match[2]
    elsif /^=end/ =~ e.line
      @level_of_heading=0
      @body << '</div>'
      @contents.itemize_end(nil)
      return
    end
    raise 'Illegal jump of heading level' if new_level>@level_of_heading+1
    @i_th_heading += 1
    @body << CONTENTS_HERE << "\n" if @i_th_heading==2
    @body << "</div>\n\n\n"        if @i_th_heading!=1 and new_level<=2
    @title=str                     if @i_th_heading==1
    cls = case new_level
          when 1 then "slide cover"
          else        "slide"
          end
    @body << "<div class=\"#{cls}\">\n" if new_level<=2
    @body << "<h#{new_level} id=\"LABEL-#{@i_th_heading}\">" << str << "</h#{new_level}>\n"
    if @contents_range === new_level
      @contents.itemize_add_primitive(1+new_level-@contents_range.first,
                                      "<a href=\"#LABEL-#{@i_th_heading}\">" + str + "</a>")
    end
    @level_of_heading=new_level
  end

  include Itemize
  def itemize_add(e)
    new_level = case e.line
                when         /^ \* (.*)/ then 1
                when       /^   \* (.*)/ then 2
                when     /^     \* (.*)/ then 3
                when   /^       \* (.*)/ then 4
                when /^         \* (.*)/ then 5
                else raise 'Illegal astarisk line for itemize'
                end
    str, is_mathml = Regexp.last_match[1].apply_subs_rules(@subs_rules)
    itemize_add_primitive(new_level,str)
    @is_mathml = @is_mathml || is_mathml
  end
  def itemize_continue(e)
    /^(\s+)(\S.*)$/.match(e.line)
    new_level = Regexp.last_match[1].length/2
    new_level=@level_of_state if new_level>@level_of_state
    raise "Illegal indent in itemize" if new_level<=0
    str, is_mathml = Regexp.last_match[2].apply_subs_rules(@subs_rules)
    itemize_continue_primitive(new_level,str)
    @is_mathml = @is_mathml || is_mathml
  end


  def parse(fd)
    while line=fd.gets || line="=end\n"
      e = Event.new(line)
      #STDERR.printf("%s\n", @state)
      #STDERR.printf("%-10s:%s", e.event, line)
      procs = TABLE[e.event][@state]
      procs.each do |i|
        send(i,e) if i.instance_of?(Symbol)
        @state=i  if i.instance_of?(String)
      end
      break if e.event=='end'
    end
  end

  def body
    if @contents_range.first<=@contents_range.last
      @body.sub(CONTENTS_HERE,"<br />Contents:"+@contents.body)
    else
      @body
    end
  end

  def html(stylesheets=["style.css"],javascripts=[],name="",language="en")
    style_lines=""
    stylesheets.each{|s| style_lines << "<link rel=\"stylesheet\" href=\"#{s}\" type=\"text/css\" />\n"}
    javascript_lines=""
    javascripts.each{|j| javascript_lines << "<script src=\"#{j}\" type=\"text/javascript\"></script>\n"}
    if @mode=='ulmul2html5'
      xml_line=''
      meta_charset_line="<meta charset=utf-8>\n  "
      doctype_lines='<!DOCTYPE html>'
      html_line='<html>'
    else
      xml_line="<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
      meta_charset_line="<meta http-equiv=\"content-type\" content=\"application/xhtml+xml; charset=utf-8\" />\n  "
      if @is_mathml
        doctype_lines='<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN"
                     "http://www.w3.org/Math/DTD/mathml2/xhtml-math11-f.dtd">'
        html_line="<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"#{language}\" dir=\"ltr\">"
      else
        doctype_lines='<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
                     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
        html_line="<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"#{language}\" lang=\"#{language}\" dir=\"ltr\">"
      end
    end
    return "#{xml_line}#{doctype_lines}
#{html_line}
<head>
  #{meta_charset_line}<title>#{@title}</title>
  <meta name=\"author\" content=\"#{name}\" />
  <meta name=\"copyright\" content=\"Copyright &#169; #{Date.today.year} #{name}\" />
  #{style_lines}#{javascript_lines}  <link rel=\"shortcut icon\" href=\"favicon.ico\" />
</head>
<body>
#{body()}
</body>
</html>
"
  end

  class Event
    attr_reader :line, :event
    def initialize(line)
      @line  = line
      @event = case line
               when /^=begin/,/^#/ then 'ignore'
               when /^=end/        then 'end'
               when /^=+ /         then 'heading'
               when /^ +\*/        then 'asterisk'
               when /^\s*$/        then 'empty'
               when /^\s+/         then 'offset'
               when /^Eq\./        then 'eq_begin'
               when /^\/Eq/        then 'eq_end'
               when /^Fig\./       then 'fig_begin'
               when /^\/Fig/       then 'fig_end'
               else 'normal'
               end
    end
  end
end
# Local variables:
#   compile-command: "ruby -I . ../bin/ulmul2html5 -c 2..3 -s ulmul2html5.css ulmul.rb > ../index.en.html"
# End:
