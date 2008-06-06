use strict;
use warnings;
use Test::Builder::Tester;
use Test::PerlbalConf tests => 2;
use File::Spec;

doit(
    q{not ok 1 - t/etc/missing_service.conf: unknown service 'my_service' is applied to 'example.com'},
    qw(t etc missing_service.conf)
);

doit(
    q{not ok 1 - t/etc/missing_pool.conf: unknown pool 'my_pool' is applied to 'my_service'},
    qw(t etc missing_pool.conf)
);

sub doit {
    my ($msg, @file) = @_;
    my $fname = File::Spec->catfile(@file);
    test_out($msg);
    test_fail(+1);
    perlbal_config_ok($fname);
    test_test("fail works: $fname");
}

