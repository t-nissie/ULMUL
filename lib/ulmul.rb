# ulmul.rb
# Time-stamp: <2010-06-16 10:43:25 takeshi>
# Author: Takeshi Nishimatsu
##
require "rubygems"
require "date"
require "math_ml/string"

# For m17n of Ruby 1.9.x. Thanks, Masayoshi Takahashi-san [ruby-list:47159].
if defined?(Encoding) && Encoding.respond_to?("default_external")
  Encoding.default_external = "UTF-8"
end

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
  VERSION = '0.4.1'
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
      meta_charset_line="<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n  "
      doctype_lines="<!DOCTYPE html>"
      html_line="<html lang=\"#{language}\">"
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
