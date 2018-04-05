include config.mk

scripts = vblr vbdb $(ILS)/bin/*

build: configure check root

install: build install-vblr
	@echo Installing root for $(ILS)
	install -d $(ROOT)
	cp -R build/root/* $(ROOT)/

configure: config.mk

config.mk:
	./configure

root: build/root/root.kv
	@bbin/build-root $(ILS)

build/root/root.kv:
	@mkdir -p build/root
	@bbin/configure.$(ILS) > $@

check:
	@bbin/check-syntax $(scripts)
	@bbin/check-prereqs $(ILS)

install-vblr: vblr
	@echo Installing vblr and vbdb
	install -d $(PREFIX)/bin
	install vblr $(PREFIX)/bin/
	install vbdb $(PREFIX)/bin/

.PHONY: all configure check build root install install-vblr
