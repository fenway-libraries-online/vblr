all: check

check:
	@perl -c vblr || exit 2

install: vblr check
	install vblr ~/bin/
	chmod 0555 ~/bin/vblr
