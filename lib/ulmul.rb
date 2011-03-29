#!/usr/bin/env ruby
# ulmul.rb
# Time-stamp: <2011-03-29 21:32:44 takeshi>
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
#    while result =~ /\$(.*?)\$/
#      pre=$`
#      tex=Regexp.last_match[1]
#      post=$'
#      result = "#{pre}#{tex.to_mathml}#{post}"
#    end
    return result
  end
end

module Itemize
  def cb_itemize_begin(filename=nil, lnumber=nil, line=nil)
    @level_of_state = 0
  end

  def cb_itemize_add_item(filename=nil, lnumber=nil, line=nil)
    new_level = case line
                when         /^ \* (.*)/ then 1
                when       /^   \* (.*)/ then 2
                when     /^     \* (.*)/ then 3
                when   /^       \* (.*)/ then 4
                when /^         \* (.*)/ then 5
                else raise 'Illegal astarisk line for itemize'
                end
    str = Regexp.last_match[1].apply_subs_rules(@subs_rules)
    if new_level>@level_of_state+1
      raise 'Illegal jump of itemize level'
    elsif new_level==@level_of_state+1
      @body << "\n" << "    "*@level_of_state << ITEMIZE_INITIATOR << "\n"
      @body <<              "    "*(new_level-1) << "  " << ITEM_INITIATOR << str
      @level_of_state = new_level
    elsif new_level==@level_of_state
      @body << ITEM_TERMINATOR << "\n" << "    "*(new_level-1) << "  " << ITEM_INITIATOR << str
    else
      @body << ITEM_TERMINATOR<< "\n"
      (@level_of_state-1).downto(new_level){|i| @body << "    "*i << ITEMIZE_TERMINATOR << ITEM_TERMINATOR << "\n"}
      @body              << "    "*(new_level-1) << "  " << ITEM_INITIATOR << str
      @level_of_state = new_level
    end
  end

  def cb_itemize_continue_item(filename=nil, lnumber=nil, line=nil)
    new_level = case line
                when         /^   (.*)/ then 1
                when       /^     (.*)/ then 2
                when     /^       (.*)/ then 3
                when   /^         (.*)/ then 4
                when /^           (.*)/ then 5
                else raise 'Illegal astarisk line for itemize'
                end
    str = Regexp.last_match[1].apply_subs_rules(@subs_rules)
    (@level_of_state-1).downto(new_level){|i| @body << ITEM_TERMINATOR << "\n" << "    "*i << ITEMIZE_TERMINATOR}
    @body << "\n  " << "    "*(new_level-1) << "  " << str
    @level_of_state = new_level
  end

  def cb_itemize_end(filename=nil, lnumber=nil, line=nil)
    @body << ITEM_TERMINATOR << "\n"
    (@level_of_state-1).downto(1){|i| @body << "    "*i << ITEMIZE_TERMINATOR << ITEM_TERMINATOR << "\n"}
    @body << ITEMIZE_TERMINATOR << "\n"
    @level_of_state = 0
  end
end

class Table_of_Contents
  include Itemize
  def initialize()
    @body = ''
    @subs_rules = []
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
  aasm_state :st_env
 
  aasm_event :ev_ignore do
    transitions :from => :st_ground,    :to => :st_ground    
    transitions :from => :st_itemize,   :to => :st_itemize   
    transitions :from => :st_verbatim,  :to => :st_verbatim
    transitions :from => :st_paragraph, :to => :st_paragraph 
    transitions :from => :st_env,       :to => :st_env    
  end

  aasm_event :ev_asterisk do
    transitions :from => :st_ground,    :to => :st_itemize,   :on_transition =>                    [:cb_itemize_begin, :cb_itemize_add_item]
    transitions :from => :st_itemize,   :to => :st_itemize,   :on_transition =>                                       [:cb_itemize_add_item]
    transitions :from => :st_verbatim,  :to => :st_verbatim,  :on_transition => [:cb_verbatim_add]
    transitions :from => :st_paragraph, :to => :st_itemize,   :on_transition => [:cb_paragraph_end, :cb_itemize_begin, :cb_itemize_add_item]
    transitions :from => :st_env,       :to => :st_env,       :on_transition => [:cb_env_continues]
  end
 
  aasm_event :ev_offset do
    transitions :from => :st_ground,    :to => :st_verbatim,  :on_transition =>                    [:cb_verbatim_begin, :cb_verbatim_add]
    transitions :from => :st_itemize,   :to => :st_itemize,   :on_transition => [:cb_itemize_continue_item]
    transitions :from => :st_verbatim,  :to => :st_verbatim,  :on_transition =>                                        [:cb_verbatim_add]
    transitions :from => :st_paragraph, :to => :st_verbatim,  :on_transition => [:cb_paragraph_end, :cb_verbatim_begin, :cb_verbatim_add]
    transitions :from => :st_env,       :to => :st_env,       :on_transition => [:cb_env_continues]
  end
 
  aasm_event :ev_heading do
    transitions :from => :st_ground,    :to => :st_ground,    :on_transition =>                    [:cb_heading]
    transitions :from => :st_itemize,   :to => :st_ground,    :on_transition =>   [:cb_itemize_end, :cb_heading]
    transitions :from => :st_verbatim,  :to => :st_ground,    :on_transition =>  [:cb_verbatim_end, :cb_heading]
    transitions :from => :st_paragraph, :to => :st_ground,    :on_transition => [:cb_paragraph_end, :cb_heading]
    transitions :from => :st_env,       :to => :st_ground,    :on_transition => [:cb_env_in_env_error]
  end
 
  aasm_event :ev_empty do
    transitions :from => :st_ground,    :to => :st_ground
    transitions :from => :st_itemize,   :to => :st_ground,    :on_transition =>   [:cb_itemize_end]
    transitions :from => :st_verbatim,  :to => :st_ground,    :on_transition =>  [:cb_verbatim_end]
    transitions :from => :st_paragraph, :to => :st_ground,    :on_transition => [:cb_paragraph_end]
    transitions :from => :st_env,       :to => :st_env
  end

  aasm_event :ev_env_begin do
    transitions :from => :st_ground,    :to => :st_env,       :on_transition =>                    [:cb_env_begin]
    transitions :from => :st_itemize,   :to => :st_env,       :on_transition =>   [:cb_itemize_end, :cb_env_begin]
    transitions :from => :st_verbatim,  :to => :st_env,       :on_transition =>  [:cb_verbatim_end, :cb_env_begin]
    transitions :from => :st_paragraph, :to => :st_env,       :on_transition => [:cb_paragraph_end, :cb_env_begin]
    transitions :from => :st_env,       :to => :st_env,       :on_transition => [:cb_env_in_env_error]
  end
 
  aasm_event :ev_env_end do
    transitions :from => [:st_ground, :st_itemize, :st_verbatim, :st_paragraph],
                                        :to => :st_ground,    :on_transition => [:cb_env_not_in_env_error]
    transitions :from => :st_env,       :to => :st_ground,    :on_transition => [:cb_env_end]
  end
 
  aasm_event :ev_normal do
    transitions :from => :st_ground,    :to => :st_paragraph, :on_transition =>                   [:cb_paragraph_begin, :cb_paragraph_add]
    transitions :from => :st_itemize,   :to => :st_paragraph, :on_transition =>  [:cb_itemize_end, :cb_paragraph_begin, :cb_paragraph_add]
    transitions :from => :st_verbatim,  :to => :st_paragraph, :on_transition => [:cb_verbatim_end, :cb_paragraph_begin, :cb_paragraph_add]
    transitions :from => :st_paragraph, :to => :st_paragraph, :on_transition =>                                        [:cb_paragraph_add]
    transitions :from => :st_env,       :to => :st_env,       :on_transition => [:cb_env_continues]
  end

  def cb_paragraph_begin(filename=nil, lnumber=nil, line=nil)
    @body << PARAGRAPH_INITIATOR << "\n"
  end

  def cb_paragraph_add(filename=nil, lnumber=nil, line=nil)
    @body << line.apply_subs_rules(@subs_rules)
  end

  def cb_paragraph_end(filename=nil, lnumber=nil, line=nil)
    @body << PARAGRAPH_TERMINATOR << "\n"
  end

  def cb_verbatim_begin(filename=nil, lnumber=nil, line=nil)
    @body << VERBATIM_INITIATOR << "\n"
  end

  def cb_verbatim_add(filename=nil, lnumber=nil, line=nil)
      @body << line[1..-1] #.gsub(/</,'&lt;').gsub(/>/,'&gt;')
  end

  def cb_verbatim_end(filename=nil, lnumber=nil, line=nil)
    @body << VERBATIM_TERMINATOR << "\n"
  end

  def cb_env_begin(filename=nil, lnumber=nil, line=nil)
    @env_label, @env_file = line.split
    @env_label.sub!(/^\\/,'')
    @env_caption =''
    cb_env_begin2()
  end

  def cb_env_continues(filename=nil, lnumber=nil, line=nil)
    @env_caption << line
  end

  def cb_env_end(filename=nil, lnumber=nil, line=nil)
    if line.chomp.sub(/^\//,'') != @env_label
      STDERR << filename << ":#{lnumber}: Current environment is #{@env_label}, but it is terminated with: #{line}"
      exit 1
    end
    cb_env_end2()
    @env_caption =''
    @env_label =''
  end

  def cb_env_in_env_error(filename=nil, lnumber=nil, line=nil)
    STDERR << filename << ":#{lnumber}: It is already/still in the environment of #{@env_label}, but you tried: #{line}"
    exit 1
  end

  def cb_env_not_in_env_error(filename=nil, lnumber=nil, line=nil)
    STDERR << filename << ":#{lnumber}: It is not in any environment, but you tried: #{line}"
    exit 1
  end

  def parse(fd)
    while true
      if line = fd.gets
        lnumber = ARGF.file.lineno
      else
        line = "=end\n"
      end
      case line
      when /^=begin/,/^#/ then    ev_ignore(nil, $FILENAME, lnumber, line)
      when /^=end/        then   ev_heading(nil, $FILENAME, lnumber, line); break
      when /^=+ /         then   ev_heading(nil, $FILENAME, lnumber, line)
      when /^ +\*/        then  ev_asterisk(nil, $FILENAME, lnumber, line)
      when /^$/           then     ev_empty(nil, $FILENAME, lnumber, line)
      when /^\s+/         then    ev_offset(nil, $FILENAME, lnumber, line)
      when /^\\(Eq|Fig|Table|Code):/
                          then ev_env_begin(nil, $FILENAME, lnumber, line)
      when /^\/(Eq|Fig|Table|Code):/
                          then   ev_env_end(nil, $FILENAME, lnumber, line)
      else                        ev_normal(nil, $FILENAME, lnumber, line)
      end
    end
  end

  def initialize()
    @toc = Table_of_Contents.new()
    @body = ''
    @level_of_heading = 0
    @i_th_heading     = 0
    @subs_rules = []
  end
  attr_accessor :subs_rules
end

#  def equation_end(e)
#    @body << @equation.to_mathml('block').to_s << "\n"
#    @equation =''
#  end

module HTML
  CONTENTS_HERE="<!-- Contents -->"
  def cb_heading(filename=nil, lnumber=nil, line=nil)
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
    cls = if new_level==1 then "slide cover" else "slide" end
    @body << "<div class=\"#{cls}\">\n" if new_level<=2
    @body << "<h#{new_level} id=\"LABEL-#{@i_th_heading}\">" << str << "</h#{new_level}>\n"
    if 2 <= new_level && new_level <= $MAX_TABLE_OF_CONTENTS
      @toc.cb_itemize_add_item('HTML Table of Contents', @i_th_heading, "  "*(new_level-2) + " * <a href=\"#LABEL-#{@i_th_heading}\">" + str + "</a>")
    end
    @level_of_heading=new_level
  end

  def cb_env_begin2()
    @body << "<figure id=\"#{@env_label}\">"  << "\n" << "  <img src=\"#{@env_file}\" alt=\"#{@env_file}\" />\n"
  end

  def cb_env_end2()
    @body << "<figcaption>\n"
    @body << @env_caption.apply_subs_rules(@subs_rules)
    @body << "</figcaption>\n"
    @body << '</figure>' << "\n"
  end

  def file(stylesheets=["style.css"],javascripts=[],name="",language="en")
    style_lines=""
    stylesheets.each{|s| style_lines << "<link rel=\"stylesheet\" href=\"#{s}\" type=\"text/css\" />\n"}
    javascript_lines=""
    javascripts.each{|j| javascript_lines << "<script src=\"#{j}\" type=\"text/javascript\"></script>\n"}
    return "<!DOCTYPE html>
<html lang=\"#{language}\">
<head>
  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />
  <title>#{@title}</title>
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

  def body
    if $MAX_TABLE_OF_CONTENTS>=2
      @body.sub(CONTENTS_HERE, "<br />\n<div class=\"table of contents\">\nTable of Contents:" +
                @toc.body + "</div>\n")
    else
      @body
    end
  end
end

module LaTeX
  def cb_heading(filename=nil, lnumber=nil, line=nil)
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
    if 2 <= new_level && new_level <= $MAX_TABLE_OF_CONTENTS
      @toc.cb_itemize_add_item('LaTeX Table of Contents', @i_th_heading, "  "*(new_level-2) + " * " + str)
    end
    @level_of_heading=new_level
  end

  def cb_env_begin2()
    @body << "\\begin{figure}\n" << "  \\center\n  \\includegraphics[width=5cm,bb=0 0 200 200]{#{@env_file}}\n"
  end

  def cb_env_end2()
    @body << '  \caption{' << @env_caption.apply_subs_rules(@subs_rules).strip << "}\n"
    @body << "  \\label{#{@env_label}}\n" << "\\end{figure}\n"
  end

  def file(packages,name)
    return "\\documentclass[a4]{article}
\\usepackage{graphicx}
\\usepackage{bm}
\\title{#{@title}}
\\author{#{name}}
\\begin{document}
\\maketitle
#{body}
\\end{document}
"
  end

  attr_reader :body
end

if $0 == __FILE__ || /ulmul2html5$/ =~ $0
  require "optparse"
  name = ENV['USER'] || ENV['LOGNAME'] || Etc.getlogin || Etc.getpwuid.name
  language = "en"
  stylesheets = []
  javascripts = []
  $MAX_TABLE_OF_CONTENTS = 3
  opts = OptionParser.new
  opts.program_name = $0
  opts.on("-s STYLESHEET_FILENAME","--style STYLESHEET_FILENAME",
          "Specify stylesheet filename."){|v| stylesheets<<v}
  opts.on("-n YOUR_NAME","--name YOUR_NAME","Specify your name."){|v| name=v}
  opts.on("-j JAVASCRIPT_FILENAME","--javascript JAVASCRIPT_FILENAME",
          "Specify JavaScript filename."){|v| javascripts<<v}
  opts.on("-l LANGUAGE","--language LANGUAGE",String,
          "Specify natural language. Its defalt is 'en'."){|v| language=v[0..1].downcase}
  opts.on("-m MAX_TABLE_OF_CONTENTS","--max-table-of-contents  MAX_TABLE_OF_CONTENTS",Integer,
          "Specify the maximum level for table of contents."){|v| $MAX_TABLE_OF_CONTENTS=v}
  opts.on_tail("-h", "--help", "Show this message."){puts opts.to_s.sub(/options/,'options] [filename'); exit}
  opts.parse!(ARGV)
  stylesheets=['ulmul2html5.css'] if stylesheets==[]

  Itemize::ITEMIZE_INITIATOR  =   '<ul>'
  Itemize::ITEMIZE_TERMINATOR =  '</ul>'
  Itemize::ITEM_INITIATOR     =   '<li>'
  Itemize::ITEM_TERMINATOR    =  '</li>'
  Ulmul::PARAGRAPH_INITIATOR  =    '<p>'
  Ulmul::PARAGRAPH_TERMINATOR =   '</p>'
  Ulmul::VERBATIM_INITIATOR   =  '<pre>'
  Ulmul::VERBATIM_TERMINATOR  = '</pre>'
  class Ulmul
    include HTML
  end
  u=Ulmul.new()
  u.subs_rules = [[/(http:\S*)(\s|$)/, '<a href="\1">\1</a>\2'],
                 [/(https:\S*)(\s|$)/, '<a href="\1">\1</a>\2']]
  u.parse(ARGF)
  puts u.file(stylesheets,javascripts,name,language)
end
