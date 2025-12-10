# sountop Makefile

PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin

SWIFT = swiftc
SWIFTFLAGS = -O

.PHONY: all clean install uninstall release

all: sountop

sountop: sountop.swift
	$(SWIFT) $(SWIFTFLAGS) -o $@ $<

clean:
	rm -f sountop

install: sountop
	install -d $(BINDIR)
	install -m 755 sountop $(BINDIR)/sountop

uninstall:
	rm -f $(BINDIR)/sountop

# Create a release tarball
release: clean
	@if [ -z "$(VERSION)" ]; then echo "Usage: make release VERSION=1.0.0"; exit 1; fi
	mkdir -p dist
	git archive --format=tar.gz --prefix=sountop-$(VERSION)/ -o dist/sountop-$(VERSION).tar.gz HEAD
	@echo "Created dist/sountop-$(VERSION).tar.gz"
	@echo "SHA256: $$(shasum -a 256 dist/sountop-$(VERSION).tar.gz | cut -d' ' -f1)"
