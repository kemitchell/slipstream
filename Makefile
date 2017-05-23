FORMS=terms
COMMONFORM=node_modules/.bin/commonform
PRODUCTS=cform hash docx pdf
BUILD=build
TARGETS=$(foreach type,$(PRODUCTS),$(addsuffix .$(type),terms))

all: $(addprefix $(BUILD)/,$(TARGETS))

%.pdf: %.docx
	unoconv $<

$(BUILD)/%.hash: %.cform | $(COMMONFORM) $(BUILD)
	$(COMMONFORM) hash $< > $@

$(BUILD)/%.docx: %.cform title blanks.json | $(COMMONFORM) $(BUILD)
	$(COMMONFORM) render --format docx --title "$(shell cat title)" --number outline --indent-margins --left-align-title --blanks blanks.json $< >$@

$(BUILD)/%.cform: %.cform | $(COMMONFORM) $(BUILD)
	$(COMMONFORM) render --format native < $< > $@

$(COMMONFORM):
	npm install

$(BUILD):
	mkdir $(BUILD)

.PHONY: clean docker

clean:
	rm -rf $(BUILD)

docker:
	docker build -t software-service-terms .
	docker run -v $(shell pwd)/$(BUILD):/app/$(BUILD) software-service-terms
	sudo chown -R `whoami`:`whoami` $(BUILD)
