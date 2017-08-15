FORMS=terms
COMMONFORM=node_modules/.bin/commonform
SPELL=node_modules/.bin/reviewers-edition-spell
PRODUCTS=cform hash docx pdf html
RELEASE=release
TARGETS=$(foreach type,$(PRODUCTS),$(addsuffix .$(type),terms))

GIT_TAG=$(strip $(shell git tag -l --points-at HEAD))
EDITION=$(if $(GIT_TAG),$(GIT_TAG),Development Draft)
ifeq ($(EDITION),development draft)
	SPELLED_EDITION=$(EDITION)
else
	SPELLED_EDITION=$(shell echo "$(EDITION)" | $(SPELL) | sed 's!draft of!draft of the!')
endif

all: $(addprefix $(RELEASE)/,$(TARGETS))

%.pdf: %.docx
	unoconv $<

$(RELEASE)/%.hash: %.cform | $(COMMONFORM) $(RELEASE)
	$(COMMONFORM) hash $< > $@

$(RELEASE)/%.docx: %.cform title blanks.json | $(COMMONFORM) $(RELEASE)
	$(COMMONFORM) render --format docx --title "$(shell cat title)" --edition "$(SPELLED_EDITION)" --number outline --indent-margins --left-align-title --blanks blanks.json --mark-filled $< >$@

$(RELEASE)/%.html: %.cform title blanks.json | $(COMMONFORM) $(RELEASE)
	$(COMMONFORM) render --format html5 --title "$(shell cat title)" --edition "$(SPELLED_EDITION)" --blanks blanks.json $< >$@

$(RELEASE)/%.cform: %.cform | $(COMMONFORM) $(RELEASE)
	$(COMMONFORM) render --format native < $< > $@

$(COMMONFORM) $(SPELL):
	npm install

$(RELEASE):
	mkdir $(RELEASE)

.PHONY: clean docker

clean:
	rm -rf $(RELEASE)

docker:
	docker build -t slipstream .
	docker run --name slipstream slipstream
	docker cp slipstream:/app/$(RELEASE) .
	docker rm slipstream
