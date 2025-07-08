#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# ulmul.rb
# Author: Takeshi Nishimatsu
##
require "rubygems"
require "date"
require "math_ml/string"
require "aasm"

# For m17n of Ruby 1.9.x. Thanks, Masayoshi Takahashi-san [ruby-list:47159].
if defined?(Encoding) && Encoding.respond_to?("default_external")
  Encoding.default_external = "UTF-8"
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
                else
                  STDERR << filename << ":" << lnumber <<
                      ": Illegally indented astarisk line in itemize: \"#{line.chomp}\"\n"
                  raise 'Illegally indented astarisk line in itemize'
                end
    str = @subs_rules.call(Regexp.last_match[1])
    if new_level>@level_of_state+1
      STDERR << filename << ":#{lnumber}: Illegal jump of itemize level from #{@level_of_state} to #{new_level}: #{line}"
      exit 1
      raise
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
                when         /^   (\S.*)/ then 1
                when       /^     (\S.*)/ then 2
                when     /^       (\S.*)/ then 3
                when   /^         (\S.*)/ then 4
                when /^           (\S.*)/ then 5
                else
                  STDERR << filename << ":" << lnumber <<
                      ": Illegally indented line in itemize: \"#{line.chomp}\"\n"
                  raise 'Illegally indented line in itemize'
                end
    str = @subs_rules.call(Regexp.last_match[1])
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
    @subs_rules = lambda{|s| return s}
    cb_itemize_begin()
  end
  attr_reader :body
end

class Ulmul
  include AASM
  include Itemize
  VERSION = '0.7.0'

  aasm.initial_state :st_ground

  aasm.state :st_ground
  aasm.state :st_itemize
  aasm.state :st_verbatim
  aasm.state :st_paragraph
  aasm.state :st_env
  aasm.state :st_equation

  aasm.event :ev_ignore do
    transitions :from => :st_ground,    :to => :st_ground
    transitions :from => :st_itemize,   :to => :st_itemize
    transitions :from => :st_verbatim,  :to => :st_verbatim
    transitions :from => :st_paragraph, :to => :st_paragraph
    transitions :from => :st_env,       :to => :st_env
    transitions :from => :st_equation,  :to => :st_equation
  end

  aasm.event :ev_asterisk do
    transitions :from => :st_ground,    :to => :st_itemize,   :after =>                    [:cb_itemize_begin, :cb_itemize_add_item]
    transitions :from => :st_itemize,   :to => :st_itemize,   :after =>                                       [:cb_itemize_add_item]
    transitions :from => :st_verbatim,  :to => :st_verbatim,  :after => [:cb_verbatim_add]
    transitions :from => :st_paragraph, :to => :st_itemize,   :after => [:cb_paragraph_end, :cb_itemize_begin, :cb_itemize_add_item]
    transitions :from => :st_env,       :to => :st_env,       :after => [:cb_env_continues]
    transitions :from => :st_equation,  :to => :st_equation,  :after => [:cb_equation_continues]
  end

  aasm.event :ev_offset do
    transitions :from => :st_ground,    :to => :st_verbatim,  :after =>                    [:cb_verbatim_begin, :cb_verbatim_add]
    transitions :from => :st_itemize,   :to => :st_itemize,   :after => [:cb_itemize_continue_item]
    transitions :from => :st_verbatim,  :to => :st_verbatim,  :after =>                                        [:cb_verbatim_add]
    transitions :from => :st_paragraph, :to => :st_verbatim,  :after => [:cb_paragraph_end, :cb_verbatim_begin, :cb_verbatim_add]
    transitions :from => :st_env,       :to => :st_env,       :after => [:cb_env_continues]
    transitions :from => :st_equation,  :to => :st_equation,  :after => [:cb_equation_continues]
  end

  aasm.event :ev_heading do
    transitions :from => :st_ground,    :to => :st_ground,    :after =>                    [:cb_heading]
    transitions :from => :st_itemize,   :to => :st_ground,    :after =>   [:cb_itemize_end, :cb_heading]
    transitions :from => :st_verbatim,  :to => :st_ground,    :after =>  [:cb_verbatim_end, :cb_heading]
    transitions :from => :st_paragraph, :to => :st_ground,    :after => [:cb_paragraph_end, :cb_heading]
    transitions :from => :st_env,       :to => :st_ground,    :after => [:cb_env_in_env_error]
    transitions :from => :st_equation,  :to => :st_equation,  :after => [:cb_equation_in_equation_error]
  end

  aasm.event :ev_empty do
    transitions :from => :st_ground,    :to => :st_ground
    transitions :from => :st_itemize,   :to => :st_ground,    :after =>   [:cb_itemize_end]
    transitions :from => :st_verbatim,  :to => :st_ground,    :after =>  [:cb_verbatim_end]
    transitions :from => :st_paragraph, :to => :st_ground,    :after => [:cb_paragraph_end]
    transitions :from => :st_env,       :to => :st_env
    transitions :from => :st_equation,  :to => :st_equation
  end

  aasm.event :ev_env_begin do
    transitions :from => :st_ground,    :to => :st_env,       :after =>                    [:cb_env_begin]
    transitions :from => :st_itemize,   :to => :st_env,       :after =>   [:cb_itemize_end, :cb_env_begin]
    transitions :from => :st_verbatim,  :to => :st_env,       :after =>  [:cb_verbatim_end, :cb_env_begin]
    transitions :from => :st_paragraph, :to => :st_env,       :after => [:cb_paragraph_end, :cb_env_begin]
    transitions :from => :st_env,       :to => :st_env,       :after => [:cb_env_in_env_error]
    transitions :from => :st_equation,  :to => :st_equation,  :after => [:cb_equation_in_equation_error]
  end

  aasm.event :ev_env_end do
    transitions :from => [:st_ground, :st_itemize, :st_verbatim, :st_paragraph, :st_equation],
                                        :to => :st_ground,    :after => [:cb_env_not_in_env_error]
    transitions :from => :st_env,       :to => :st_ground,    :after => [:cb_env_end]
  end

  aasm.event :ev_equation_begin do
    transitions :from => :st_ground,    :to => :st_equation,  :after =>                    [:cb_paragraph_begin, :cb_equation_begin]
    transitions :from => :st_itemize,   :to => :st_equation,  :after =>   [:cb_itemize_end, :cb_paragraph_begin, :cb_equation_begin]
    transitions :from => :st_verbatim,  :to => :st_equation,  :after =>  [:cb_verbatim_end, :cb_paragraph_begin, :cb_equation_begin]
    transitions :from => :st_paragraph, :to => :st_equation,  :after =>                                         [:cb_equation_begin]
    transitions :from => :st_equation,  :to => :st_equation,  :after => [:cb_equation_in_equation_error]
  end

  aasm.event :ev_equation_end do
    transitions :from => [:st_ground, :st_itemize, :st_verbatim, :st_paragraph, :st_env],
                                        :to => :st_ground,    :after => [:cb_equation_not_in_equation_error]
    transitions :from => :st_equation,  :to => :st_paragraph, :after => [:cb_equation_end]
  end

  aasm.event :ev_normal do
    transitions :from => :st_ground,    :to => :st_paragraph, :after =>                   [:cb_paragraph_begin, :cb_paragraph_add]
    transitions :from => :st_itemize,   :to => :st_paragraph, :after =>  [:cb_itemize_end, :cb_paragraph_begin, :cb_paragraph_add]
    transitions :from => :st_verbatim,  :to => :st_paragraph, :after => [:cb_verbatim_end, :cb_paragraph_begin, :cb_paragraph_add]
    transitions :from => :st_paragraph, :to => :st_paragraph, :after =>                                        [:cb_paragraph_add]
    transitions :from => :st_env,       :to => :st_env,       :after => [:cb_env_continues]
    transitions :from => :st_equation,  :to => :st_equation,  :after => [:cb_equation_continues]
  end

  def cb_paragraph_begin(filename=nil, lnumber=nil, line=nil)
    @body << PARAGRAPH_INITIATOR << "\n"
  end

  def cb_paragraph_add(filename=nil, lnumber=nil, line=nil)
    @body << @subs_rules.call(line)
  end

  def cb_paragraph_end(filename=nil, lnumber=nil, line=nil)
    @body << PARAGRAPH_TERMINATOR << "\n"
  end

  def cb_verbatim_begin(filename=nil, lnumber=nil, line=nil)
    @body << VERBATIM_INITIATOR << "\n"
  end

  def cb_verbatim_add(filename=nil, lnumber=nil, line=nil)
      @body << line[1..-1].gsub(/&/,'&amp;').gsub(/</,'&lt;').gsub(/>/,'&gt;')
  end

  def cb_verbatim_end(filename=nil, lnumber=nil, line=nil)
    @body << VERBATIM_TERMINATOR << "\n"
  end

  def cb_env_begin(filename=nil, lnumber=nil, line=nil)
    @env_label, @env_file = line.split
    @env_label.sub!(/^\\/,'')
    @env_caption =''
    case @env_label
    when /^Fig:/
      @figures << @env_label
    when /^Table:/
      @tables << @env_label
    when /^Code:/
      @codes << @env_label
    end
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

  def cb_equation_begin(filename=nil, lnumber=nil, line=nil)
    @equation_label = line.strip.sub!(/^\\/,'')
    @equations << @equation_label
    @equation_contents = ''
  end

  def cb_equation_continues(filename=nil, lnumber=nil, line=nil)
    @equation_contents << line
  end

  def cb_equation_end(filename=nil, lnumber=nil, line=nil)
    cb_equation_end2()
    @equation_contents =''
    @equation_label =''
  end

  def parse(fd)
    while true
      if line = fd.gets
        lnumber = ARGF.file.lineno
      else
        line = "=end\n"
      end
      case line
      when /^=begin/,/^#/ then    ev_ignore($FILENAME, lnumber, line)
      when /^=end/        then   ev_heading($FILENAME, lnumber, line); break
      when /^=+ /         then   ev_heading($FILENAME, lnumber, line)
      when /^ +\*/        then  ev_asterisk($FILENAME, lnumber, line)
      when /^$/           then     ev_empty($FILENAME, lnumber, line)
      when /^\s+/         then    ev_offset($FILENAME, lnumber, line)
      when /^\\(Fig|Table|Code):/
                          then ev_env_begin($FILENAME, lnumber, line)
      when /^\/(Fig|Table|Code):/
                          then   ev_env_end($FILENAME, lnumber, line)
      when /^\\Eq:/  then ev_equation_begin($FILENAME, lnumber, line)
      when /^\/Eq:/  then   ev_equation_end($FILENAME, lnumber, line)
      else                        ev_normal($FILENAME, lnumber, line)
      end
    end
  end

  def initialize()
    @toc = Table_of_Contents.new()
    @body = ''
    @level_of_heading = 0
    @i_th_heading     = 0
    @equations       = []
    @figures         = []
    @tables          = []
    @codes           = []
  end
  attr_accessor :subs_rules
end

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

  def body
    b = @body.dup
    [@equations, @figures, @tables, @codes].each do |ary|
      ary.each_with_index do |r,i|
        s = r.sub(/:.*/,'')
        if /Eq|Fig/ =~ s then s << '.' end
        if /Eq/     =~ s then no = "(#{i+1})" else no = "#{i+1}" end
        b.gsub!(Regexp.new('(?![A-Za-z0-9_"\'#%\\\\])(.)'+r+'(?![A-Za-z0-9_"\'#%])(.)'),"\\1<a href=\"##{r}\">#{s} #{no}</a>\\2")
      end
    end
    if $MAX_TABLE_OF_CONTENTS>=2
      b.sub(CONTENTS_HERE, "<br />\n<div class=\"table of contents\">\nTable of Contents:" +
                @toc.body + "</div>\n")
    else
      b
    end
  end

  def cb_env_end2table()
      @body << "<table  id=\"#{@env_label}\">\n"
      @body << "  <caption>\n"
      @body << "  Table #{@tables.length}: " << @subs_rules.call(@env_caption)
      @body << "  </caption>\n"
      @body << "  <thead><tr><th>       TABLE           </th></tr></thead>\n"
      @body << "  <tbody><tr><td>Not yet implemented</td></tr></tbody>\n"
      @body << '</table>' << "\n"
  end

  def cb_env_end2code()
    @body << "<p id=\"#{@env_label}\" class=\"code caption\">\n"
    @body << "  Code #{@codes.length}: " << @subs_rules.call(@env_caption) << "(download: <a href=\"#{@env_file}\">#{File.basename(@env_file)}</a>)" << "</p>\n"
    @body << "<pre class=\"prettyprint\">\n"
    begin
      open(@env_file){|f| @body << f.read.gsub(/&/,'&amp;').gsub(/</,'&lt;').gsub(/>/,'&gt;')}
    rescue Errno::ENOENT => ex
      STDERR << ex << "\n"
      exit 1
    end
    @body << "</pre>\n"
  end

  def cb_equation_end2()
    if $0 == __FILE__ || /ulmul2(html5|xhtml)$/ =~ $0
      @body << @equation_contents.to_mathml('block').to_s.sub(/<math /,"<math id=\"#{@equation_label}\" ") << "\n"
    elsif /ulmul2mathjax$/ =~ $0
      @body << "<div id=\"#{@equation_label}\">\n\\begin{equation}\n" << @equation_contents << "  \\tag{#{@equations.length}}\n" << "\\end{equation}\n</div>\n"
    end
  end
end

module HTML5
  def cb_env_end2()
    case @env_label
    when /^Fig:/
      @body << "<figure id=\"#{@env_label}\">\n" << "  <img src=\"#{@env_file}\" alt=\"#{@env_file}\" />\n"
      @body << "  <figcaption>\n"
      @body << "  Figure #{@figures.length}: " << @subs_rules.call(@env_caption)
      @body << "  </figcaption>\n" << '</figure>' << "\n"
    when /^Table:/
      cb_env_end2table()
    when /^Code:/
      cb_env_end2code()
    end
  end

  def file(stylesheets=["ulmul2html5.css"],javascripts=[],name="",language="en")
    style_lines=""
    stylesheets.each{|s| style_lines << "  <link rel=\"stylesheet\" href=\"#{s}\" type=\"text/css\" />\n"}
    javascript_lines=""
    javascripts.each{|j| javascript_lines << "  <script src=\"#{j}\" type=\"text/javascript\"></script>\n"}
    return "<!DOCTYPE html>
<html lang=\"#{language}\">
<head>
  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />
  <title>#{@title}</title>
  <meta name=\"author\" content=\"#{name}\" />
  <script type=\"text/x-mathjax-config\">
    MathJax.Hub.Config({
      tex2jax: {
        inlineMath: [ ['$','$'] ]
      }
    });
  </script>
#{style_lines}#{javascript_lines}  <link rel=\"icon\" href=\"favicon.ico\" />
</head>
<body onload=\"prettyPrint()\">
#{body()}
</body>
</html>
"
  end
end

module XHTML
  def cb_env_end2()
    case @env_label
    when /^Fig:/
      @body << "<div class=\"figure\" id=\"#{@env_label}\">\n" << "  <img src=\"#{@env_file}\" alt=\"#{@env_file}\" />\n"
      @body << "  <div class=\"figcaption\">\n"
      @body << "  Figure #{@figures.length}. " << @subs_rules.call(@env_caption)
      @body << "  </div>\n"
      @body << '</div>' << "\n"
    when /^Table:/
      cb_env_end2table()
    when /^Code:/
      cb_env_end2code()
    end
  end

  def file(stylesheets=["ulmul2xhtml.css"],javascripts=[],name="",language="en")
    style_lines=""
    stylesheets.each{|s| style_lines << "  <link rel=\"stylesheet\" href=\"#{s}\" type=\"text/css\" />\n"}
    javascript_lines=""
    javascripts.each{|j| javascript_lines << "<script src=\"#{j}\" type=\"text/javascript\"></script>\n"}
    return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE html
  PUBLIC \"-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN\"
         \"http://www.w3.org/Math/DTD/mathml2/xhtml-math11-f.dtd\">
<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\">

<head>
  <meta name=\"language\" content=\"#{language}\" />
  <title>#{@title}</title>
  <meta name=\"author\" content=\"#{name}\" />
  <meta name=\"copyright\" content=\"Copyright &#169; #{Date.today.year} #{name}\" />
  #{style_lines}#{javascript_lines}  <link rel=\"icon\" href=\"favicon.ico\" />
</head>
<body onload=\"prettyPrint()\">
#{body()}
</body>
</html>
"
  end
end

module LaTeX
  require 'exifr'
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

  def cb_env_end2()
    case @env_label
    when /^Fig:/
      begin
        width  = EXIFR::JPEG.new(@env_file).width
        height = EXIFR::JPEG.new(@env_file).height
      rescue Errno::ENOENT => ex
        STDERR << ex << "\n"
        exit 1
      end
      @body << "\\begin{figure}\n" << "  \\center\n  \\includegraphics[width=5cm,bb=0 0 #{width} #{height}]{#{@env_file}}\n"
      @body << '  \caption{' << @subs_rules.call(@env_caption).strip << "}\n"
      @body << "  \\label{#{@env_label}}\n" << "\\end{figure}\n"
    when /^Table:/
      @body << "\\begin{table}\n"
      @body << '  \caption{' << @subs_rules.call(@env_caption).strip << "}\n"
      @body << "  \\label{#{@env_label}}\n"
      @body << "  \\center\n"
      @body << "  {TABLE is not yet implemented.}\n"
      @body << "\\end{table}\n"
    when /^Code:/
      @body << "\\begin{lstlisting}[caption={#{@subs_rules.call(@env_caption).strip}},label=#{@env_label}]\n"
      begin
        open(@env_file){|f| @body << f.read}
      rescue Errno::ENOENT => ex
        STDERR << ex << "\n"
        exit 1
      end
      @body << "\\end{lstlisting}\n"
    end
  end

  def cb_equation_end2()
    @body << "\\begin{equation}\n" << "  \\label{#{@equation_label}}\n"
    @body << @equation_contents
    @body << "\\end{equation}\n"
  end

  def file(packages,name)
    return "\\documentclass{article}
\\usepackage{graphicx}
\\usepackage{bm}
\\usepackage{listings}
\\renewcommand{\\lstlistingname}{Code}
\\lstset{language=c,
%  basicstyle=\\ttfamily\\scriptsize,
%  commentstyle=\\textit,
%  classoffset=1,
%  keywordstyle=\\bfseries,
   frame=shadowbox,
%  framesep=5pt,
%  showstringspaces=false,
%  numbers=left,
%  stepnumber=1,
%  numberstyle=\\tiny,
%  tabsize=2
}
\\title{#{@title}}
\\author{#{name}}
\\begin{document}
\\maketitle
#{body}
\\end{document}
"
  end

  def body
    b = @body.dup
    [@equations, @figures, @tables, @codes].each do |ary|
      ary.each_with_index do |r,i|
        s = r.sub(/:.*/,'')
        if /Eq|Fig/ =~ s then s << '.' end
        if /Eq/     =~ s then no = "(\\ref{#{r}})" else no = "\\ref{#{r}}" end
        b.gsub!(Regexp.new('(?![A-Za-z0-9_"\'#%\\\\{\=])(.)'+r+'(?![A-Za-z0-9_"\'#%}])(.)'), "\\1#{s}~#{no}\\2")
      end
    end
    return b
  end
end

if $0 == __FILE__ || /ulmul2(html5|xhtml|mathjax)$/ =~ $0
  Version = Ulmul::VERSION
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
  opts.on("-m MAX_TABLE_OF_CONTENTS","--max-table-of-contents MAX_TABLE_OF_CONTENTS",Integer,
          "Specify the maximum level for table of contents."){|v| $MAX_TABLE_OF_CONTENTS=v}
  opts.on_tail("-h", "--help", "Show this message."){puts opts.to_s.sub(/options/,'options] [filename'); exit}
  opts.parse!(ARGV)

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
    if /ulmul2xhtml$/ =~ $0
      include XHTML
    else
      include HTML5
    end
  end
  u=Ulmul.new()
  if $0 == __FILE__ || /ulmul2(html5|xhtml)$/ =~ $0
    u.subs_rules = lambda{|s| s.gsub(/&/,'&amp;').
                                gsub(/</,'&lt;').
                                gsub(/>/,'&gt;').
                                gsub(/(http:\S*|https:\S*)(\s|$)/, '<a href="\1">\1</a>\2').
                                gsub(/\$(.*?)\$/){|s| Regexp.last_match[1].to_mathml}}
  else
    u.subs_rules = lambda{|s| s.gsub(/&/,'&amp;').
                                gsub(/</,'&lt;').
                                gsub(/>/,'&gt;').
                                gsub(/(http:\S*|https:\S*)(\s|$)/, '<a href="\1">\1</a>\2')}
  end
  u.parse(ARGF)
  puts u.file(stylesheets,javascripts,name,language)
end
# Local variables:
#   compile-command: "./ulmul.rb -s ../ulmul2html5.css -s ../google-code-prettify/src/prettify.css -j ../google-code-prettify/src/prettify.js test.ulmul | tee test.html"
# End:
