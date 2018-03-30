include config.mk

all: check

check:
	@perl -c vblr || exit 2

install:
	@echo Please make install-for-koha or install-for-voyager

install-for-koha: install-vblr koha/bin/ils.load
	rsync -av koha/bin/ $(VBLR_ROOT)/bin/

install-for-voyager: install-vblr voyager/bin/ils.load
	rsync -av voyager/bin/ $(VBLR_ROOT)/bin/

install-vblr: vblr check
	install -d $(PREFIX)/bin
	install vblr $(PREFIX)/bin/
	install vbdb $(PREFIX)/bin/
