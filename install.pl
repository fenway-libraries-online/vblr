#!/usr/bin/perl

use strict;
use warnings;

use Config;

sub fatal;
sub usage;
sub note;

usage if @ARGV != 1;

my $ils = lc shift @ARGV;
$ils =~ /^(voyager|koha)$/ or fatal "unsupported ILS: $ils";

my ($perl, $self) = ($^X, $0);
my $interactive = -t STDIN;
my ($lib, $bin, $man) = @Config{qw(sitelib sitebin siteman1dir)};

check_permissions();
install_prereqs();
install_vblr();
create_files($ils);

# --- Functions

sub check_permissions {
    my $superuser = ($> == 0) ? 1 : 0;
    if ($superuser) {
        note "You've got root.";
        foreach ($lib, $bin, $man) {
            xmkdir($lib) if !-d $_;
            fatal "But you can't install into $_" if !-w $_;
        }
    }
    elsif (!-w $lib || !-w $bin || !-w $man) {
        note "Must become root";
        { exec 'sudo', $perl, $self }
        fatal "It looks like sudo isn't available, or you entered the wrong password";
    }
}

sub install_prereqs {
    my @install_mods;
    open my $fh, '<', 'vblr' or fatal "open vblr: $!";
    while (<$fh>) {
        last if $. == 500;
        next if !/^use\s+([A-Z][^\s;]+)/;
        next if eval "require $1";
        push @install_mods, $1;
    }
    if (@install_mods) {
        note "Modules that need to be installed:",
            map { "* $_" } @install_mods;
        if (eval "require App::Cpanminus") {
            exit(2) if !askbool('Shall I use cpanm to install these modules?');
            run('cpanm', @install_mods);
            note "All modules successfully installed";
        }
    }
}

sub install_vblr {
    run('install', 'vblr', $bin);
    # run('install', '-m' => '0644', 'vblr.pod', $man);
}

sub create_files {
    xmkdir('~/proj');
    foreach ('base', $ils) {
        run('rsync', -qav => "$_/", glob('~/proj/'));
    }
}

sub xmkdir {
    foreach (map { glob $_ } @_) {
        -d $_ or mkdir $_ or fatal "mkdir $_: $!";
    }
}

sub run {
    my $cmd = shift;
    return 1 if system($cmd, @_) == 0;
    fatal "$cmd @_ :: $!";
}

sub note {
    print STDERR $_, "\n" for @_;
}

sub fatal {
    print STDERR "install.pl: $_\n" for @_;
    exit 2;
}

