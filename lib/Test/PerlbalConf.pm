package Test::PerlbalConf;
use strict;
use warnings;
use 5.00800;
our $VERSION = '0.01';
use base qw/Test::Builder::Module/;
use Carp;
use UNIVERSAL::require;
use Perlbal;

my $CLASS = __PACKAGE__;

our @EXPORT = qw(perlbal_config_ok recurse_perlbal_config_ok);

our %SERVICE;
our %POOL;
our $LAST_CREATED;
our @FINALIZER;
our $ERROR;

sub _die(@) { ## no critic
    my @msg = @_;
    $ERROR ||= "@msg";
}

sub _parse {
    my ($cmd, $re) = @_;
    my @ret = ($cmd =~ $re);
    _die "cannot parse $cmd" unless @ret;
    @ret;
}

my $command_parser = {
    load => sub {
        my $cmd = shift;
        my ($fn,) = _parse($cmd, qr/^load (\w+)$/);
        my $load = sub {
            my $name = shift;
            my $rv = "Perlbal::Plugin::$name"->use;
            _die $@ if !$rv && $@ !~ /^Can\'t locate/;
            return $rv;
        };
        my $rv = $load->($fn) || $load->(lc $fn) || $load->(ucfirst lc $fn);
    },
    create => sub {
        my $cmd = shift;
        my ($what, $name) = _parse( $cmd, qr/^create (service|pool) (\w+)$/);

        if ( $what eq "service" ) {
            _die("service '$name' already exists") if $SERVICE{$name};
            _die("pool '$name' already exists") if $POOL{$name};
            $SERVICE{$name}++;
            $LAST_CREATED = $name;
        } elsif ( $what eq "pool" ) {
            _die "pool '$name' already exists"    if $POOL{$name};
            _die "service '$name' already exists" if $SERVICE{$name};
            $POOL{$name}++;
            $LAST_CREATED = $name;
        }
    },
    set => sub {
        my $cmd = shift;
        my ($name, $key, $val) = _parse($cmd, qr/^set (?:(\w+)[\. ])?([\w\.]+) ?= ?(.+)$/);
        _die "omitted service/pool name not implied from context" unless $LAST_CREATED;

        unless ($SERVICE{$LAST_CREATED} || $POOL{$LAST_CREATED}) {
            _die "hm... strange : $LAST_CREATED";
        }

        # this is ad-hoc. but works well
        if ($key eq 'pool') {
            my $service = $LAST_CREATED;
            push @FINALIZER, sub {
                _die "unknown pool '$val' is applied to '$service'" unless $POOL{$val};
            };
        }
    },
    enable => sub {
        my $cmd = shift;
        my ($verb, $name) = _parse($cmd, qr/^(disable|enable) (\w+)$/);
        _die "service '$name' does not exist" unless $SERVICE{$name};
    },
    vhost => sub {
        # see Perlbal::Plugin::Vhosts
        my $cmd = shift;
        my ($selname, $host, $target) = _parse($cmd, qr/^vhost\s+(?:(\w+)\s+)?(\S+)\s*=\s*(\w+)$/);
        unless ($selname ||= $LAST_CREATED) {
            _die "omitted service name not implied from context";
        }
        # TODO: check "Service '$selname' is not a selector service"
        _die "invalid host pattern: '$host'" unless $host =~ /^[\w\-\_\.\*\;\:]+$/;

        push @FINALIZER, sub {
            _die "unknown service '$target' is applied to '$host'" unless $SERVICE{$target};
        };
    },
};

sub perlbal_config_ok {
    my $fname = shift;

    local %SERVICE            = ();
    local %POOL               = ();
    local @FINALIZER          = ();
    local $LAST_CREATED       = undef;
    local $ERROR              = undef;

    open my $fh, '<', $fname or die "$fname: $!";

    while (my $line = <$fh>) {
        $line =~ s/\$(\w+)/$ENV{$1}/g; # expand $USER => tokuhirom
        _test_manage_command($line);
    }

    close $fh;

    for my $finalizer (@FINALIZER) {
        $finalizer->();
    }

    $CLASS->builder->ok( !$ERROR, $ERROR ? "$fname: $ERROR" : "$fname looks good" );
}

sub _test_manage_command {
    my $cmd = shift;

    $cmd =~ s/\#.*//;
    $cmd =~ s/^\s+//;
    $cmd =~ s/\s+$//;
    $cmd =~ s/\s+/ /g;

    my $orig = $cmd; # save original case for some commands
    $cmd =~ s/^([^=]+)/lc $1/e; # lowercase everything up to an =
    return 1 unless $cmd =~ /^\S/;

    # expand variables
    $cmd =~ s/\$\{(.+?)\}/_expand_config_var($1)/eg;

    _die "invalid command: $cmd" unless $cmd =~ qr{^(\w+)};

    my $basecmd = $1;

    if ($command_parser->{$basecmd}) {
        $command_parser->{$basecmd}->($cmd);
    } else {
        $CLASS->builder->diag("unknown command $basecmd");
    }
}

sub _expand_config_var {
    my $cmd = shift;

    $cmd =~ /^(\w+):(.+)/ or die "Unknown config variable: $cmd\n";

    my ($type, $val) = ($1, $2);
    if ($type eq 'ip') {
        _die "Test::PerlbalConf does not support expand ip yet";
    }
    _die "Unknown config variable type: $type\n";
}

1;
__END__

=for stopwords configtest Perlbal perlbal

=encoding utf8

=head1 NAME

Test::PerlbalConf - config tester for Perlbal

=head1 SYNOPSIS

    use Test::PerlbalConf;

    perlbal_config_ok('etc/perlbal.conf');

=head1 DESCRIPTION

Test::PerlbalConf is configtest for perlbal.

THIS MODULE IS STILL IN ALPHA QUALITY!

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
