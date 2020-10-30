FORMS=terms
CFCM=node_modules/.bin/commonform-commonmark
CFDOCX=node_modules/.bin/commonform-docx
CFHTML=node_modules/.bin/commonform-html
JSON=node_modules/.bin/json
SPELL=node_modules/.bin/reviewers-edition-spell
PRODUCTS=docx pdf html
TARGETS=$(foreach type,$(PRODUCTS),$(addsuffix .$(type),terms))

GIT_TAG=$(strip $(shell git tag -l --points-at HEAD))
EDITION=$(if $(GIT_TAG),$(GIT_TAG),Development Draft)
ifeq ($(EDITION),development draft)
	SPELLED_EDITION=$(EDITION)
else
	SPELLED_EDITION=$(shell echo "$(EDITION)" | $(SPELL) | sed 's!draft of!draft of the!')
endif

all: $(addprefix release/,$(TARGETS))

%.pdf: %.docx
	unoconv $<

release/%.docx: release/%.form release/%.title release/%.values release/%.directions release/%.styles | $(COMMONFORM) release
	$(CFDOCX) \
		--title "$(shell cat release/$*.title)" \
		--edition "$(SPELLED_EDITION)" \
		--values release/$*.values \
		--directions release/$*.directions \
		--mark-filled \
		--styles release/$*.styles \
		--number outline \
		--indent-margins \
		--left-align-title \
		--smartify \
		$< > $@

release/%.html: release/%.form release/%.title release/%.values release/%.directions | $(COMMONFORM) release
	$(CFHTML) \
		--title "$(shell cat release/$*.title)" \
		--edition "$(SPELLED_EDITION)" \
		--values release/$*.values \
		--directions release/$*.directions \
		--ids \
		--lists \
		--smartify \
		< $< > $@

release/%.parsed: %.md | release $(CFCM)
	$(CFCM) parse $< > $@

release/%.form: release/%.parsed | release $(JSON)
	$(JSON) form < $< > $@

release/%.directions: release/%.parsed | release $(JSON)
	$(JSON) directions < $< > $@

release/%.title: release/%.parsed | release $(JSON)
	$(JSON) frontMatter.title < $< > $@

release/%.values: release/%.parsed | release $(JSON)
	$(JSON) frontMatter.blanks < $< > $@

release/%.styles: release/%.parsed | release $(JSON)
	$(JSON) frontMatter.styles < $< > $@

$(COMMONFORM) $(SPELL):
	npm install

release:
	mkdir release

.PHONY: clean docker

clean:
	rm -rf release

DOCKER_TAG=slipstream
docker:
	docker build -t $(DOCKER_TAG) .
	docker run --name $(DOCKER_TAG) $(DOCKER_TAG)
	docker cp $(DOCKER_TAG):/workdir/release .
	docker rm $(DOCKER_TAG)
