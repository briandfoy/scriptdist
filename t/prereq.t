# $Id$
use Test::More;
eval "use Test::Prereq 0.51";
plan skip_all => "Test::Prereq 0.51 required to test dependencies" if $@;
prereq_ok();
