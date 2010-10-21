# -*-Makefile-*- for md.tex
##
LATEX2E=platex

all: abst.dvi abst.pdf
	grep 'Warning' *.log ; true

%.pdf: %.dvi dvipdfmx.map
	dvipdfmx -f dvipdfmx.map -p a4 $< > $@

%.dvi: %.tex ulmul.bst ulmul.bib
	platex $<
	jbibtex `basename $< .tex`
	platex $<
	platex $<

clean:
	rm -f abst.aux abst.bbl abst.blg abst.dvi abst.log abst.pdf
