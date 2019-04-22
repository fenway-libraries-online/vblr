package App::vblr::Plugin::hello;

sub new {
    my $cls = shift;
    bless { @_ }, $cls;
}

sub skip_orient { 1 }

sub cmd {
    my $self = shift;
    unshift @_, 'who' if !@_;
    print "Hello @_\n";
}

sub hook_loading {
    my $self = shift;
    1;
}

1;
