#!/usr/bin/perl

use strict;
use warnings;

use Config;

sub fatal;
sub usage;
sub note;

my ($perl, $self) = ($^X, $0);
my $interactive = -t STDIN;

my ($ils, $user, $root) = @ARGV;

$ils =~ /^(voyager|koha)$/ or fatal "unsupported ILS: $ils";

if (!defined $user) {
    my ($name, undef, undef, undef, undef, undef, undef, $dir) = getpwuid($<);
    fatal "can't find home directory" if !defined $dir;
    fatal "no home directory" if !-d $dir;
    ($user, $root) = ($name, "$dir/proj");
}
elsif (!defined $root) {
    my ($name, undef, undef, undef, undef, undef, undef, $dir) = getpwnam($user);
    fatal "no such user: $user" if !defined $dir;
    fatal "no home directory for user: $user" if !-d $dir;
    $root = "$dir/proj";
}
my @passwd = getpwnam($user);
fatal "no such user: $user" if !@passwd;
my $group = getgrgid($passwd[3]);
fatal "no group for user: $user" if !$group;

my ($lib, $bin, $man) = @Config{qw(sitelib sitebin siteman1dir)};

check_permissions();
install_prereqs();
install_vblr();
create_files($ils, $root);

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
    my ($ils, $root) = @_;
    xmkdir($root);
    foreach ('base', $ils) {
        run('rsync', -qav => "$_/", "$root/");
    }
    run('chown', '-R', "$user.$group", $root);
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

sub usage {
    print STDERR "usage: install.pl ILS [USER]\n";
    exit 1;
}
