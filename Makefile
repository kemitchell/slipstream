FORMS=terms
CFCM=node_modules/.bin/commonform-commonmark
CFDOCX=node_modules/.bin/commonform-docx
CFHTML=node_modules/.bin/commonform-html
JSON=node_modules/.bin/json
PRODUCTS=docx pdf html
TARGETS=$(foreach type,$(PRODUCTS),$(addsuffix .$(type),terms))

all: $(addprefix build/,$(TARGETS))

build/%.pdf: build/%.docx
	soffice --headless --convert-to pdf --outdir build "$<"

build/%.docx: build/%.form build/%.title build/%.version build/%.values build/%.directions build/%.styles | $(CFDOCX) build
	$(CFDOCX) \
		--title "$(shell cat build/$*.title)" \
		--form-version "$(shell cat build/$*.version)" \
		--values build/$*.values \
		--directions build/$*.directions \
		--mark-filled \
		--styles build/$*.styles \
		--number outline \
		--indent-margins \
		--left-align-title \
		--left-align-body \
		--smart \
		$< > $@

build/%.html: build/%.form build/%.title build/%.version build/%.values build/%.directions | $(CFHTML) build
	$(CFHTML) \
		--title "$(shell cat build/$*.title)" \
		--form-version "$(shell cat build/$*.version)" \
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

build/%.version: build/%.parsed | build $(JSON)
	$(JSON) frontMatter.version < $< > $@

build/%.values: build/%.parsed | build $(JSON)
	$(JSON) frontMatter.blanks < $< > $@

build/%.styles: build/%.parsed | build $(JSON)
	$(JSON) frontMatter.styles < $< > $@

$(CFCM) $(CFDOCX) $(CFHTML) $(JSON) $(SPELL):
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
