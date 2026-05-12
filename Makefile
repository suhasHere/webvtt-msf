DRAFT = draft-wilaw-moq-webvtt-msf
KRAMDOWN = /Users/snk/.gem/ruby/2.6.0/gems/kramdown-rfc2629-1.7.31/bin/kramdown-rfc

all: $(DRAFT).txt $(DRAFT).html

$(DRAFT).xml: $(DRAFT).md
	$(KRAMDOWN) $(DRAFT).md > $(DRAFT).xml

$(DRAFT).txt: $(DRAFT).xml
	xml2rfc --text $(DRAFT).xml

$(DRAFT).html: $(DRAFT).xml
	xml2rfc --html $(DRAFT).xml

clean:
	rm -f $(DRAFT).txt $(DRAFT).html $(DRAFT).xml

.PHONY: all clean
