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

all: $(addprefix build/,$(TARGETS))

build/%.pdf: build/%.docx
	soffice --headless --convert-to pdf --outdir build "$<"

build/%.docx: build/%.form build/%.title build/%.values build/%.directions build/%.styles | $(COMMONFORM) build
	$(CFDOCX) \
		--title "$(shell cat build/$*.title)" \
		--edition "$(SPELLED_EDITION)" \
		--values build/$*.values \
		--directions build/$*.directions \
		--mark-filled \
		--styles build/$*.styles \
		--number outline \
		--indent-margins \
		--left-align-title \
		--smartify \
		$< > $@

build/%.html: build/%.form build/%.title build/%.values build/%.directions | $(COMMONFORM) build
	$(CFHTML) \
		--title "$(shell cat build/$*.title)" \
		--edition "$(SPELLED_EDITION)" \
		--values build/$*.values \
		--directions build/$*.directions \
		--ids \
		--lists \
		--smartify \
		< $< > $@

build/%.parsed: %.md | build $(CFCM)
	$(CFCM) parse $< > $@

build/%.form: build/%.parsed | build $(JSON)
	$(JSON) form < $< > $@

build/%.directions: build/%.parsed | build $(JSON)
	$(JSON) directions < $< > $@

build/%.title: build/%.parsed | build $(JSON)
	$(JSON) frontMatter.title < $< > $@

build/%.values: build/%.parsed | build $(JSON)
	$(JSON) frontMatter.blanks < $< > $@

build/%.styles: build/%.parsed | build $(JSON)
	$(JSON) frontMatter.styles < $< > $@

$(COMMONFORM) $(SPELL):
	npm install

build:
	mkdir build

.PHONY: clean docker

clean:
	rm -rf build

DOCKER_TAG=slipstream
docker:
	docker build -t $(DOCKER_TAG) .
	docker run --name $(DOCKER_TAG) $(DOCKER_TAG)
	docker cp $(DOCKER_TAG):/workdir/build .
	docker rm $(DOCKER_TAG)
