# -*-Makefile-*-
# Time-stamp: <2010-11-23 19:39:07 takeshi>
##
all: nishimatsu-ajt.pdf

%.pdf: %.tex %.bib nishimatsu-ajt.bst
	pdflatex $<
	bibtex `basename $< .tex`
	pdflatex $<
	pdflatex $<

clean:
	rm -f nishimatsu-ajt.aux\
              nishimatsu-ajt.bbl\
              nishimatsu-ajt.blg\
              nishimatsu-ajt.log\
              nishimatsu-ajt.out\
              nishimatsu-ajt.pdf
