FORMS=terms
CFCM=node_modules/.bin/commonform-commonmark
CFDOCX=node_modules/.bin/commonform-docx
CFHTML=node_modules/.bin/commonform-html
JSON=node_modules/.bin/json
SPELL=node_modules/.bin/reviewers-edition-spell
PRODUCTS=docx pdf html
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

$(RELEASE)/%.docx: $(RELEASE)/%.form $(RELEASE)/%.title $(RELEASE)/%.values $(RELEASE)/%.directions $(RELEASE)/%.styles | $(COMMONFORM) $(RELEASE)
	$(CFDOCX) \
		--title "$(shell cat $(RELEASE)/$*.title)" \
		--edition "$(SPELLED_EDITION)" \
		--values $(RELEASE)/$*.values \
		--directions $(RELEASE)/$*.directions \
		--mark-filled \
		--styles $(RELEASE)/$*.styles \
		--number outline \
		--indent-margins \
		--left-align-title \
		--smartify \
		$< > $@

$(RELEASE)/%.html: $(RELEASE)/%.form $(RELEASE)/%.title $(RELEASE)/%.values $(RELEASE)/%.directions | $(COMMONFORM) $(RELEASE)
	$(CFHTML) \
		--title "$(shell cat $(RELEASE)/$*.title)" \
		--edition "$(SPELLED_EDITION)" \
		--values $(RELEASE)/$*.values \
		--directions $(RELEASE)/$*.directions \
		--ids \
		--lists \
		--smartify \
		< $< > $@

$(RELEASE)/%.parsed: %.md | $(RELEASE) $(CFCM)
	$(CFCM) parse $< > $@

$(RELEASE)/%.form: $(RELEASE)/%.parsed | $(RELEASE) $(JSON)
	$(JSON) form < $< > $@

$(RELEASE)/%.directions: $(RELEASE)/%.parsed | $(RELEASE) $(JSON)
	$(JSON) directions < $< > $@

$(RELEASE)/%.title: $(RELEASE)/%.parsed | $(RELEASE) $(JSON)
	$(JSON) frontMatter.title < $< > $@

$(RELEASE)/%.values: $(RELEASE)/%.parsed | $(RELEASE) $(JSON)
	$(JSON) frontMatter.blanks < $< > $@

$(RELEASE)/%.styles: $(RELEASE)/%.parsed | $(RELEASE) $(JSON)
	$(JSON) frontMatter.styles < $< > $@

$(COMMONFORM) $(SPELL):
	npm install

$(RELEASE):
	mkdir $(RELEASE)

.PHONY: clean docker

clean:
	rm -rf $(RELEASE)

DOCKER_TAG=slipstream
docker:
	docker build -t $(DOCKER_TAG) .
	docker run --name $(DOCKER_TAG) $(DOCKER_TAG)
	docker cp $(DOCKER_TAG):/workdir/$(RELEASE) .
	docker rm $(DOCKER_TAG)
