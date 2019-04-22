package App::vblr::Plugin::html;

sub new {
    my $cls = shift;
    bless { @_ }, $cls;
}

sub skip_orient { 1 }  # XXX Just temporarily

sub cmd {
    my ($self, @args) = @_;
    my $app = $self->{'vblr'};
    my $root = $app->root;
    print STDERR "Pretend I just generated some HTML...\n";
    return;

    my $www = $app->read_config('www');
    my $www_root = $www->{'file-root'};
    my $url_base = $www->{'url-base'};
    my $gzip = (($www->{'compress'} || 0) =~ /^[yt1]/i);

    #@ html [-nzig] [-j JOB|-S SET] [-m DESC] [-o PATH] [-s URL] [UPD [BATCH]] :: Make a web page showing records
    #@ Options:
    #@   -n         dry run
    #@   -z         compress output using gzip
    #@   -i         link 001 fields
    #@   -g         generate source file (from Voyager) if it doesn't exist
    #@   -j JOB     show records from JOB
    #@   -S SET     show records from SET
    #@   -m DESC    brief description of the records
    #@   -o PATH    file to create
    #@   -s URL     stylesheet URL (repeatable)
    my $www = rdkvfile("$root/conf/www.kv");
    my $www_root = $www->{'file-root'};
    my $url_base = $www->{'url-base'};
    my $gzip = bool($www->{'compress'});
    my ($j, $s);
    my ($dry_run, $title, $description, $inmarc, $outhtml, $outmarc, $link001, $autogen, $verbose);
    my @stylesheets;
    GetOptions(
        'n'   => \$dry_run,
        'j=s' => \$j,
        'S=s' => \$s,
        't=s' => \$title,
        'm=s' => \$description,
        'o=s' => \$outhtml,
        's=s' => \@stylesheets,
        'i'   => \$link001,
        'g'   => \$autogen,
        'z'   => \$gzip,
        'v'   => \$verbose,
    ) or usage;
    @stylesheets = qw(/records/styles.css) if !@stylesheets;
    my ($u, $b) = resolve_update_and_batch(@ARGV);
    my $code = $project->{'code'};
    my @links;
    my $first = 1;
    if (defined $s) {
        my $sdir = "sets/$s";
        die "No such set: $s" if !-d $sdir;
        push @links, rdlinks($sdir);
        my $set = rdset($s);
        $description = $set->{'description'} || "Records in set $s";
    }
    elsif (defined $j) {
        $link001 = 1;
        $b = '*' if !defined $b;
        $u = '*' if !defined $u;
        my ($inmarcdir) = files("updates/$u/batches/$b/jobs/$j");
        die "No such job: $j" if !$inmarcdir;
        push @links, map { ('-a' => $_) } rdlinks($inmarcdir);
        my $bdir = dirname(dirname($inmarcdir));
        my $udir = dirname(dirname($bdir));
        $u = basename($udir) if $u eq '*';
        $b = basename($bdir) if $b eq '*';
        my $job = rdjob($u, $b, $j);
        my $purpose = $job->{'purpose'} || ADD;
        if ($purpose eq DELETE) {
            $inmarc = "$inmarcdir/output/$j.delete";
            if (!-e $inmarc) {
                die "No file $j.delete in $inmarcdir/output";
            }
            if (!defined $description) {
                my $when = strftime('%a %-d %b %Y at %-I:%M%P', localtime((stat $inmarc)[9]));
                $description = "These are the records in job $j that were deleted on $when.";
            }
        }
        else {
            $inmarc = "$inmarcdir/loaded.mrc";
            if (!-e $inmarc) {
                die "No loaded.mrc file in $inmarcdir" if !$autogen;
                open my $fh, '-|', 'vjobget', $j or die "Can't run vjobget: $!";
                copy($fh, $inmarc);
            }
        }
        $title ||= "Job $j records";
        if (!defined $description) {
            my $when = strftime('%a %-d %b %Y at %-I:%M%P', localtime((stat $inmarc)[9]));
            $description = "These are the records in job $j as they existed in Voyager as of $when.";
        }
        $outhtml ||= $j . '.html';
    }
    elsif (defined $b) {
        $inmarc = "updates/$u/batches/$b/\@prepared/records.mrc";
        my $udesc = $u eq 'BASE' ? 'the base file' : "update $u";
        $first = $1 if $b =~ /^(\d+)-/;
        $title ||= "Project $code preview";
        if (!defined $description) {
            my $when = strftime('%a %-d %b %Y at %-I:%M%P', localtime((stat $inmarc)[9]));
            $description = "This is a preview of $udesc (records $b) as prepared for loading on $when.";
        }
        push @links, map { ('-a' => $_) } rdlinks("updates/$u/batches/$b");
    }
    elsif (defined $u) {
        $inmarc = files("updates/$u/*.mrc");
        my $udesc = $u eq 'BASE' ? 'the base file' : "update $u";
        $title ||= "Project $code records";
        $description ||= "These are the records in $udesc as they were received.";
        push @links, map { ('-a' => $_) } rdlinks("updates/$u");
    }
    else {
        usage;
    }
    if (!defined $outhtml) {
        $outhtml = $outmarc = mkid('f') . '.html';
    }
    else {
        $outhtml =~ s/(?:\.html)?$/.html/;
    }
    ($outmarc = $outhtml) =~ s/(?:\.html)?$/.mrc/;
    my @cmd = (
        'marc2html',
        '-1Dnh',
        '-N' => $first,
        '-t' => $title,
        '-p' => $description,
        '-a' => basename($outmarc) . ' Raw MARC records',
        @links,
        '-a' => '../ Project page',
    );
    #
    push @cmd, '-s', $_ for @stylesheets;
    push @cmd, '-i', rdkvfile("$root/conf/catalog.kv")->{'record-link'} if $link001;
    push @cmd, $inmarc;
    my $url    = "$url_base/$code/preview/$outhtml";
    if ($dry_run) {
        print STDERR "Dry run: @cmd\n";
        print STDERR "URL:     $url\n";
        return;
    }
    print STDERR "URL: $url\n" if $verbose;
    my $predir = "$www_root/$code/preview";
    makedir(dirname(dirname($predir)), dirname($predir), $predir);
    my ($copy, $err);
    if ($gzip) {
        $copy = \&gzip;
        $err = sub { die "gzip to $_[0] failed: $GzipError" };
        $_ .= '.gz' for $outhtml, $outmarc;
    }
    else {
        $copy = \&copy;
        $err = sub { die "copy to $_[0] failed: $!" };
    }
    for ($outhtml, $outmarc) {
        $_ = $predir . '/' . $_;
    }
    if ($verbose) {
        print STDERR "Generating output files:\n";
        for ($outhtml, $outmarc) {
            print STDERR $_, "\n";
        }
    }
    open my $fh, '-|', @cmd or die "Can't run marc2html: $!";
    $copy->($fh,     $outhtml) or $err->($outhtml);
    $copy->($inmarc, $outmarc) or $err->($outmarc);
}

sub hook_prepared {
    my $self = shift;
    1;
}

sub hook_loaded {
    my $self = shift;
    1;
}

sub mkhtml {
}

1;

