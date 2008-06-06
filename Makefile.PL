use inc::Module::Install;
name 'Test-PerlbalConf';
all_from 'lib/Test/PerlbalConf.pm';

# requires '';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More';
test_requires 'YAML';
author_tests('xt');
use_test_base;
auto_include;
WriteAll;
