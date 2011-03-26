# ulmul.rb
# Time-stamp: <2011-03-26 13:40:11 takeshi>
# Author: Takeshi Nishimatsu
##
require "rubygems"
#require "date"
#require "math_ml/string"
require "aasm"

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
  def cb_itemize_begin(line=nil)
    @level_of_state = 0
  end

  def cb_itemize_add_item(line)
    new_level = case line
                when         /^ \* (.*)/ then 1
                when       /^   \* (.*)/ then 2
                when     /^     \* (.*)/ then 3
                when   /^       \* (.*)/ then 4
                when /^         \* (.*)/ then 5
                else raise 'Illegal astarisk line for itemize'
                end
    str = Regexp.last_match[1]  #.apply_subs_rules(@subs_rules)
    if new_level>@level_of_state+1
      raise 'Illegal jump of itemize level'
    elsif new_level==@level_of_state+1
      @body << "\n" << "    "*@level_of_state << $ULMUL_ITEMIZE_INITIATOR << "\n"
      @body <<              "    "*(new_level-1) << "  " << $ULMUL_ITEM_INITIATOR << str
      @level_of_state = new_level
    elsif new_level==@level_of_state
      @body << $ULMUL_ITEM_TERMINATOR << "\n" << "    "*(new_level-1) << "  " << $ULMUL_ITEM_INITIATOR << str
    else
      @body << $ULMUL_ITEM_TERMINATOR<< "\n"
      (@level_of_state-1).downto(new_level){|i| @body << "    "*i << $ULMUL_ITEMIZE_TERMINATOR << $ULMUL_ITEM_TERMINATOR << "\n"}
      @body              << "    "*(new_level-1) << "  " << $ULMUL_ITEM_INITIATOR << str
      @level_of_state = new_level
    end
  end

  def cb_itemize_continue_item(line)
    new_level = case line
                when         /^   (.*)/ then 1
                when       /^     (.*)/ then 2
                when     /^       (.*)/ then 3
                when   /^         (.*)/ then 4
                when /^           (.*)/ then 5
                else raise 'Illegal astarisk line for itemize'
                end
    str = Regexp.last_match[1]  #.apply_subs_rules(@subs_rules)
    (@level_of_state-1).downto(new_level){|i| @body << $ULMUL_ITEM_TERMINATOR << "\n" << "    "*i << $ULMUL_ITEMIZE_TERMINATOR}
    @body << "\n  " << "    "*(new_level-1) << "  " << str
    @level_of_state = new_level
  end

  def cb_itemize_end(line=nil)
    @body << $ULMUL_ITEM_TERMINATOR << "\n"
    (@level_of_state-1).downto(1){|i| @body << "    "*i << $ULMUL_ITEMIZE_TERMINATOR << $ULMUL_ITEM_TERMINATOR << "\n"}
    @body << $ULMUL_ITEMIZE_TERMINATOR << "\n"
    @level_of_state = 0
  end
end

class Table_of_Contents
  include Itemize
  def initialize()
    @body = ''
    cb_itemize_begin()
  end
  attr_reader :body
end

class Ulmul
  include AASM
  include Itemize
  VERSION = '0.5.0'
 
  aasm_initial_state :st_ground
 
  aasm_state :st_ground
  aasm_state :st_itemize
  aasm_state :st_verbatim
  aasm_state :st_paragraph
  aasm_state :st_figure
 
  aasm_event :ev_ignore do
    transitions :from => :st_ground,    :to => :st_ground    
    transitions :from => :st_itemize,   :to => :st_itemize   
    transitions :from => :st_verbatim,  :to => :st_verbatim
    transitions :from => :st_paragraph, :to => :st_paragraph 
    transitions :from => :st_figure,    :to => :st_figure    
  end

  aasm_event :ev_asterisk do
    transitions :from => :st_ground,    :to => :st_itemize,   :on_transition =>                    [:cb_itemize_begin, :cb_itemize_add_item]
    transitions :from => :st_itemize,   :to => :st_itemize,   :on_transition =>                                       [:cb_itemize_add_item]
    transitions :from => :st_verbatim,  :to => :st_verbatim,  :on_transition => [:cb_verbatim_add]
    transitions :from => :st_paragraph, :to => :st_itemize,   :on_transition => [:cb_paragraph_end, :cb_itemize_begin, :cb_itemize_add_item]
    transitions :from => :st_figure,    :to => :st_figure,    :on_transition => [:cb_figure_continues]
  end
 
  aasm_event :ev_offset do
    transitions :from => :st_ground,    :to => :st_verbatim,  :on_transition =>                    [:cb_verbatim_begin, :cb_verbatim_add]
    transitions :from => :st_itemize,   :to => :st_itemize,   :on_transition => [:cb_itemize_continue_item]
    transitions :from => :st_verbatim,  :to => :st_verbatim,  :on_transition =>                                        [:cb_verbatim_add]
    transitions :from => :st_paragraph, :to => :st_verbatim,  :on_transition => [:cb_paragraph_end, :cb_verbatim_begin, :cb_verbatim_add]
    transitions :from => :st_figure,    :to => :st_figure,    :on_transition => [:cb_figure_continues]
  end
 
  aasm_event :ev_heading do
    transitions :from => :st_ground,    :to => :st_ground,    :on_transition =>                    [:cb_heading]
    transitions :from => :st_itemize,   :to => :st_ground,    :on_transition =>   [:cb_itemize_end, :cb_heading]
    transitions :from => :st_verbatim,  :to => :st_ground,    :on_transition =>  [:cb_verbatim_end, :cb_heading]
    transitions :from => :st_paragraph, :to => :st_ground,    :on_transition => [:cb_paragraph_end, :cb_heading]
    transitions :from => :st_figure,    :to => :st_ground,    :on_transition => [:cb_figure_error]
  end
 
  aasm_event :ev_empty do
    transitions :from => :st_ground,    :to => :st_ground
    transitions :from => :st_itemize,   :to => :st_ground,    :on_transition =>   [:cb_itemize_end]
    transitions :from => :st_verbatim,  :to => :st_ground,    :on_transition =>  [:cb_verbatim_end]
    transitions :from => :st_paragraph, :to => :st_ground,    :on_transition => [:cb_paragraph_end]
    transitions :from => :st_figure,    :to => :st_figure,    :on_transition => [:cb_figure_error]
  end

  aasm_event :ev_normal do
    transitions :from => :st_ground,    :to => :st_paragraph, :on_transition =>                   [:cb_paragraph_begin, :cb_paragraph_add]
    transitions :from => :st_itemize,   :to => :st_paragraph, :on_transition =>  [:cb_itemize_end, :cb_paragraph_begin, :cb_paragraph_add]
    transitions :from => :st_verbatim,  :to => :st_paragraph, :on_transition => [:cb_verbatim_end, :cb_paragraph_begin, :cb_paragraph_add]
    transitions :from => :st_paragraph, :to => :st_paragraph, :on_transition =>                                        [:cb_paragraph_add]
    transitions :from => :st_figure,    :to => :st_figure,    :on_transition => [:cb_figure_continues]
  end

  def cb_paragraph_begin(line=nil)
    @body << $ULMUL_PARAGRAPH_INITIATOR << "\n"
  end

  def cb_paragraph_add(line)
    # result, is_mathml = e.line.apply_subs_rules(@subs_rules)
    @body << line
    # @is_mathml = @is_mathml || is_mathml
  end

  def cb_paragraph_end(line=nil)
    @body << $ULMUL_PARAGRAPH_TERMINATOR << "\n"
  end

  def cb_verbatim_begin(line=nil)
    @body << $ULMUL_VERBATIM_INITIATOR << "\n"
  end

  def cb_verbatim_add(line)
      @body << line[1..-1] #.gsub(/</,'&lt;').gsub(/>/,'&gt;')
  end

  def cb_verbatim_end(line=nil)
    @body << $ULMUL_VERBATIM_TERMINATOR << "\n"
  end

  def parse(fd)
    while line=fd.gets || line="=end\n"
      case line
      when /^=begin/,/^#/ then ev_ignore(nil,line)
      when /^=end/        then ev_heading(nil,line); break
      when /^=+ /         then ev_heading(nil,line)
      when /^ +\*/        then ev_asterisk(nil,line)
      when /^$/           then ev_empty(nil,line)
      when /^\s+/         then ev_offset(nil,line)
      when /^Eq\./        then ev_eq_begin(nil,line)
      when /^\/Eq/        then ev_eq_end(nil,line)
      when /^Fig\./       then ev_fig_begin(nil,line)
      when /^\/Fig/       then ev_fig_end(nil,line)
      else ev_normal(nil,line)
      end
    end
  end

  def initialize()
    @toc = Table_of_Contents.new()
    @body = ''
    @level_of_heading = 0
    @i_th_heading     = 0
  end
end

class Ulmul_Old
  VERSION = '0.4.2'
  CONTENTS_HERE="<!-- Contents -->"
  CONTENTS_RANGE_DEFAULT=2..3

#       @figure_open  =  '<figure>'
#       @figure_close = '</figure>'
#       @caption_open  =  '<figcaption>'
#       @caption_close = '</figcaption>'

#       @figure_open  =  '<div class="figure">'
#       @figure_close = '</div>'
#       @caption_open  =  '<div class="figcaption">'
#       @caption_close = '</div>'

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
end

module HTML
  CONTENTS_HERE="<!-- Contents -->"
  def cb_heading(line=nil)
    if /^(=+) (.*)$/ =~ line
      new_level=Regexp.last_match[1].length
      str=Regexp.last_match[2]
    elsif /^=end/ =~ line
      @level_of_heading=0
      @body << '</div>'
      @toc.cb_itemize_end()
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
    if 2 <= new_level && new_level <= $MAX_CONTENTS
      @toc.cb_itemize_add_item("  "*(new_level-2) + " * <a href=\"#LABEL-#{@i_th_heading}\">" + str + "</a>")
    end
    @level_of_heading=new_level
  end

  def body
    if $MAX_CONTENTS>=2
      @body.sub(CONTENTS_HERE, "<br />\n<div class=\"table of contents\">\nTable of Contents:" +
                @toc.body + "</div>\n")
    else
      @body
    end
  end
end

module LaTeX
  def cb_heading(line=nil)
    if /^(=+) (.*)$/ =~ line
      new_level=Regexp.last_match[1].length
      str=Regexp.last_match[2]
    elsif /^=end/ =~ line
      @level_of_heading=0
      @toc.cb_itemize_end()
      return
    end
    raise 'Illegal jump of heading level' if new_level>@level_of_heading+1
    @title=str                                 if new_level==1
    @body <<       '\section{' << str << "}\n" if new_level==2
    @body <<    '\subsection{' << str << "}\n" if new_level==3
    @body << '\subsubsection{' << str << "}\n" if new_level==4
    @body <<            '\bf{' << str << "}\n" if new_level==5
    if 2 <= new_level && new_level <= $MAX_CONTENTS
      @toc.cb_itemize_add_item("  "*(new_level-2) + " * <a href=\"#LABEL-#{@i_th_heading}\">" + str + "</a>")
    end
    @level_of_heading=new_level
  end

  attr_reader :body
end

if $0 == __FILE__ || /ulmul2html5$/ =~ $0
  $ULMUL_ITEMIZE_INITIATOR    =   '<ul>'
  $ULMUL_ITEMIZE_TERMINATOR   =  '</ul>'
  $ULMUL_ITEM_INITIATOR       =   '<li>'
  $ULMUL_ITEM_TERMINATOR      =  '</li>'
  $ULMUL_PARAGRAPH_INITIATOR  =    '<p>'
  $ULMUL_PARAGRAPH_TERMINATOR =   '</p>'
  $ULMUL_VERBATIM_INITIATOR   =  '<pre>'
  $ULMUL_VERBATIM_TERMINATOR  = '</pre>'
  $MAX_CONTENTS = 3

  require "optparse"
  name = ENV['USER'] || ENV['LOGNAME'] || Etc.getlogin || Etc.getpwuid.name
  language = "en"
  stylesheets = []
  javascripts = []
  opts = OptionParser.new
  def opts.usage
    return to_s.sub(/options/,'options] [filename')
  end
  opts.on("-s STYLESHEET_FILENAME","--style STYLESHEET_FILENAME",
          "Specify stylesheet filename."){|v| stylesheets<<v}
  opts.on("-n YOUR_NAME","--name YOUR_NAME","Specify your name."){|v| name=v}
  opts.on("-j JAVASCRIPT_FILENAME","--javascript JAVASCRIPT_FILENAME",
          "Specify JavaScript filename."){|v| javascripts<<v}
  opts.on("-l LANGUAGE","--language LANGUAGE",String,
          "Specify natural language. Its defalt is 'en'."){|v| language=v[0..1].downcase}
  opts.on_tail("-h", "--help", "Show this message."){puts opts.usage; exit}

  opts.parse!(ARGV)
  stylesheets=['ulmul2html5.css'] if stylesheets==[]

  class Ulmul2html5 < Ulmul
    include HTML
  end
  u=Ulmul2html5.new()
  u.parse(ARGF)
  puts u.body
end
