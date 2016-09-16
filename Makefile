all: check

check:
	@vperl -c vblr || exit 2

install: vblr check
	install vblr ~voyager/bin/
	chmod 0555 ~voyager/bin/vblr
