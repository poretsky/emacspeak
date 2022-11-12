#$Id$
# Note: Building the info pages requires package hydra to be installed.
# Built info pages are checked into GitHub.
# You should need to rebuild info files
#*only* if you change the Emacspeak Lisp sources.
#http://emacspeak.sf.net/info
SF_HOME= raman,emacspeak@web.sourceforge.net:/home/groups/e/em/emacspeak/htdocs/info
#https://tvraman.github.io/emacspeak/manual
GH_PAGES=../../gh-pages-emacspeak/manual
BATCH = -batch -q -no-site-file     \
--eval '(setq file-name-handler-alist nil gc-cons-threshold 128000000)'
FILES=*.texi


MAKEINFO = makeinfo 
CSS=--css-ref="http://www.w3.org/StyleSheets/Core/Modernist"
TEXI2HTML=texi2any --set-customization-variable TEXI2HTML=1
infodir =/usr/share/info#normally supplied by caller
INSTALL = install
EMACS=emacs

all: info html introducing-emacspeak turning-twenty emacspeak.pdf

info: emacspeak.info introducing-emacspeak.info turning-twenty.info

install: emacspeak.info turning-twenty.info
	if test  -x /usr/bin/install-info ; then \
		install-info emacspeak.info ${infodir}/dir ;\
		install-info turning-twenty.info ${infodir}/dir ; \
	fi
	$(INSTALL)  -m 644 *.info* $(infodir)

uninstall:
	if test  -e /usr/bin/install-info ; then \
		install-info --delete $(infodir)/emacspeak.info* ${infodir}/dir \;
		install-info --delete $(infodir)/turning-20.info * ${infodir}/dir \;
	fi
	rm -f $(infodir)/*.info*

html: emacspeak.texi
	$(TEXI2HTML) --split chapter --output $@ $<

emacspeak.pdf: emacspeak.texi docs.texi
	makeinfo --pdf emacspeak.texi
	rm -f emacspeak.aux emacspeak.cp emacspeak.cps emacspeak.fn \
emacspeak.fns emacspeak.ky emacspeak.kys emacspeak.log \
emacspeak.toc  emacspeak.vr emacspeak.vrs

man: emacspeak.texi 
	makeinfo -o ${GH_PAGES}  --html  ${CSS} emacspeak.texi
	tidy -q -utf8 -mic -asxml  ${GH_PAGES}/*.html 2>&1 > /dev/null  || echo tidy
	@echo "Commit and push updated HTML files from gh-pages!"

introducing-emacspeak: introducing-emacspeak.texi
	$(TEXI2HTML) --split chapter --output $@ $<

turning-twenty: turning-twenty.texi
	$(TEXI2HTML) --split chapter --output $@ $<

publish:
	cd ../../gh-pages-emacspeak && make

introducing-emacspeak.html: introducing-emacspeak.texi
	makeinfo --no-split --html  introducing-emacspeak.texi
	perl add-css.pl introducing-emacspeak.html
#For publishing to SF
pub:  html/index.html introducing-emacspeak.html
	rsync introducing-emacspeak.html ${SF_HOME}
	rsync -avz  html ${SF_HOME}/info/

%.info: %.texi
	$(MAKEINFO) $<

clean: 
	rm -f *.info* *.html *.ps *.dvi *.pdf *.txt
	rm -rf html introducing-emacspeak

spell:
	@mv .spell.words .spell.tex
	@cat ${FILES} | aspell --ignore-case -t --list --add-filter texinfo   \
 | sort | uniq > .spell.words
	@diff .spell.tex .spell.words

tags:
	etags *.texi
