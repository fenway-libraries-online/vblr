include config.mk

scripts = vblr vbdb $(ILS)/bin/*

all: check

check:
	@build/check-syntax $(scripts)
	@build/check-prereqs $(ILS)

install: check install-for-$(ILS)
	@echo Installing for $(ILS)

install-for-koha: install-vblr koha/bin/ils.load
	@build/make-root $(ILS) $(ROOT)
	cp -R koha/bin $(ROOT)/

install-for-voyager: install-vblr voyager/bin/ils.load
	@build/make-root $(ILS) $(ROOT)

install-vblr: vblr
	install -d $(PREFIX)/bin
	install vblr $(PREFIX)/bin/
	install vbdb $(PREFIX)/bin/
