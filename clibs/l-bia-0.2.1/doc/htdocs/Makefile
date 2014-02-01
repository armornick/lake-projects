##  Makefile to build L-Bia htdocs

SHELL=/bin/sh
TXT2TAGS=txt2tags
HTDOCS=license.html history.html index.html

all:
	@$(MAKE) -si htdocs

htdocs: $(HTDOCS)

license.html: license.t2t ../../LICENSE lbtopbar.html
history.html: history.t2t ../../HISTORY lbtopbar.html
index.html: index.t2t ../../README lbtopbar.html

clean:
	@echo $(RM) $(HTDOCS)
	@$(RM) $(HTDOCS)

erase: clean

.PHONY: all htdocs clean erase

.SUFFIXES:
.SUFFIXES: .t2t .html

.t2t.html:
	$(TXT2TAGS) -t html $<
