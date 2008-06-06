use strict;
use warnings;
use Test::PerlbalConf tests => 1;
use File::Spec;

perlbal_config_ok(File::Spec->catfile('t', 'etc', 'group.conf'));

