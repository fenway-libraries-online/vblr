include config.mk

scripts = vblr vbdb $(ILS)/bin/*

all: check

check:
	@echo 'Checking scripts...' >&2
	@build/check-syntax $(scripts)

install: check install-for-$(ILS)
	@echo Installing for $(ILS)

install-for-koha: install-vblr koha/bin/ils.load
	rsync -av koha/bin/ $(ROOT)/bin/

install-for-voyager: install-vblr voyager/bin/ils.load
	rsync -av voyager/bin/ $(ROOT)/bin/

install-vblr: vblr
	install -d $(PREFIX)/bin
	install vblr $(PREFIX)/bin/
	install vbdb $(PREFIX)/bin/
