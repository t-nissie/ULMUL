# -*-Makefile-*-
# Time-stamp: <2010-11-05 22:35:27 takeshi>
##
all: nishimatsu-ajt.pdf

%.pdf: %.tex %.bib
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
