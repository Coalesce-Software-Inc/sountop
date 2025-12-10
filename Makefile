# soundmon Makefile

PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin

SWIFT = swiftc
SWIFTFLAGS = -O

.PHONY: all clean install uninstall release

all: soundmon

soundmon: soundmon.swift
	$(SWIFT) $(SWIFTFLAGS) -o $@ $<

clean:
	rm -f soundmon

install: soundmon
	install -d $(BINDIR)
	install -m 755 soundmon $(BINDIR)/soundmon

uninstall:
	rm -f $(BINDIR)/soundmon

# Create a release tarball
release: clean
	@if [ -z "$(VERSION)" ]; then echo "Usage: make release VERSION=1.0.0"; exit 1; fi
	mkdir -p dist
	git archive --format=tar.gz --prefix=soundmon-$(VERSION)/ -o dist/soundmon-$(VERSION).tar.gz HEAD
	@echo "Created dist/soundmon-$(VERSION).tar.gz"
	@echo "SHA256: $$(shasum -a 256 dist/soundmon-$(VERSION).tar.gz | cut -d' ' -f1)"
