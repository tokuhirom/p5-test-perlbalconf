use strict;
use warnings;
use Test::PerlbalConf tests => 3;
use File::Spec;

perlbal_config_ok(File::Spec->catfile('t', 'etc', 'echoservice.conf'));
perlbal_config_ok(File::Spec->catfile('t', 'etc', 'webserver.conf'));
perlbal_config_ok(File::Spec->catfile('t', 'etc', 'ssl.conf'));

