SHELL:=/bin/bash

### <CONFIG> ###

# BIB files
bib.cr				= kwarccrossrefs.bib extcrossrefs.bib
bib.kcr 			= kwarcpubs.bib $(bib.cr)
bib.ext				= extpubs.bib $(bib.kcr)
bib.all				= preamble.bib $(bib.ext)
bib.people			= mkohlhase akohlhase miancu dginev cjucovschi twiesing dmueller frabe cprodescu clange cdavid vzholudev cmueller nmueller fhorozal

# Sources
src				= src/
bib.src				= ./
ltxml.src			= $(src)ltxml/
tex.src				= $(src)tex/
html.src			= $(src)html/
pubs.src			= $(src)pubs/

# Destination
dist				= dist/
bib.dist			= ./kwarc.bib
ltxml.dist			= $(dist)ltxml/
tex.dist			= $(dist)tex/
html.dist			= $(dist)html/
pubs.dist			= $(dist)pubs/

# Scripts etc
bib.sty				= $(ltxml.src)kwarcbibs.sty
html.script 			= $(html.src)generate-html
CRXSL				= $(ltxml.src)crossrefs.xsl
PLXSL				= $(pubs.src)publist.xsl

### </CONFIG> ###

# FOR kwarc.bib files
kwarc.bib.in		= $(bib.all:%=$(bib.src)%)

# for kwarc.bib.xml files
kwarc.ltxml.in		= $(bib.sty) $(bib.sty).ltxml
kwarc.ltxml.out		= $(bib.ext:%=$(ltxml.dist)%.xml)
kcr.src			= $(bib.kcr:%=$(bib.src)%)
kcr.ltxml.in		= $(ltxml.dist)kcr.bib
kcr.ltxml.tmp		= $(ltxml.dist)pre-kcr.bib.xml
kcr.ltxml.out		= $(kcr.ltxml.in).xml

### TARGETS ###

all: dist
clean: clean-bib clean-xml clean-html clean-pubs

dist: bib xml pubs

# kwarc.bib --> concat files
bib: setup-bib $(bib.dist)
setup-bib:
	mkdir -p $(dist)
clean-bib:
	-rm $(bib.dist)
$(bib.dist): 
	awk 'FNR==1{print ""}{print}' $(kwarc.bib.in) > $(bib.dist)

# *.bib.xml --> use latexmlc
xml: setup-xml $(kwarc.ltxml.out)
setup-xml:
	mkdir -p $(ltxml.dist)
clean-xml: 
	-rm -r $(ltxml.dist)
$(kwarc.ltxml.out): $(ltxml.dist)%.xml: $(bib.src)% $(kwarc.ltxml.in)
	latexmlc $< --bibtex --includestyles --path=$(ltxml.src) --preload=$(bib.sty).ltxml --destination=$@ 2> >(tee $@.ltxlog >&2)

# kcr.bib.xlm --> use latexmlc after generating kcr.bib
$(kcr.ltxml.in): $(kcr.src)
	cat $(kcr.src) > $@
$(kcr.ltxml.out): $(kcr.ltxml.in)
	latexmlc $< --bibtex --includestyles --path=$(ltxml.src) --preload=$(bib.sty).ltxml --destination=$@.tmp 2> >(tee $@.ltxlog >&2)
	xsltproc -o $@ $(CRXSL) $@.tmp
	rm -f $@.tmp

# *.html --> custom script (xsltproc + latexml)
html: setup-html $(kcr.ltxml.out)
	$(SHELL) $(html.script) $(src) $(dist) "$(bib.people)"
setup-html:
	mkdir -p $(html.dist)
	mkdir -p ${tex.dist}
	mkdir -p $(ltxml.dist)
clean-html:
	-rm -r $(html.dist)
	-rm -r ${tex.dist}

# pubs --> xsltproc
pubs: setup-pubs html $(bib.people)
setup-pubs:
	mkdir -p $(pubs.dist)
	cp $(pubs.src)publist.css $(pubs.dist)
clean-pubs:
	-rm -r $(pubs.dist)
$(bib.people): %: $(PLXSL)
	mkdir -p $(pubs.dist)$@
	xsltproc --path $(html.dist) --stringparam id $@ -o $(pubs.dist)$@/index.html $(PLXSL) $(PLXSL)


######## testing
test: $(kcr.ltxml.out)

echo:
	@echo $(kwarc.ltxml.out)
