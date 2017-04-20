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

$(BUILD)/%.docx: %.cform | $(COMMONFORM) $(BUILD)
	$(COMMONFORM) render --format docx --title "Software Terms" --number outline --indent-margins --left-align-title $< >$@

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
	docker build -t developer-tool-service-terms .
	docker run -v $(shell pwd)/$(BUILD):/app/$(BUILD) developer-tool-service-terms
	sudo chown -R `whoami`:`whoami` $(BUILD)
