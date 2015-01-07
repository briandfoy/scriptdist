require 5.010;
use strict;
use warnings;


my $script_name = 'scriptdist';

my $github    = 'https://github.com/briandfoy/';
my $main_file = 'lib/';

my %WriteMakefile = (
	'NAME'          => $script_name,
	'ABSTRACT_FROM' => $main_file,
	'VERSION_FROM'  => '0.23',
	'LICENSE'       => 'perl',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',

	'EXE_FILES' =>  [ $script_name ],

	'CONFIGURE_REQUIRES' => {
		'ExtUtils::MakeMaker' => '6.64',
		},

	'BUILD_REQUIRES' => {
		},

	'TEST_REQUIRES' => {
		'Test::More' => '0.95',
		},

	'PREREQ_PM'     => {
		'File::Path' => '2.00',
		},

	'META_MERGE' => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => "$github.git",
				web  => $github,
				},
			bugtraker => {
				web    => "$github/issues",
				},
			homepage => $github,
			},
		no_index => {
			dir       => [ qw( t ) ],
			directory => [ qw( t ) ],
			},
		},

	clean => { FILES => "*.bak $script_name-* " .
		"t/test_home_dir/test_script.d" },
	);

1;

sub arguments { \%WriteMakefile }

do_it() unless caller;
sub do_it {
	require File::Spec;
	my $MM ='ExtUtils::MakeMaker';
	my $MM_version =
		eval{ "$MM " . $WriteMakefile{'CONFIGURE_REQUIRES'}{'ExtUtils::MakeMaker'} }
			//
		"$MM 6.64";
	eval "use $MM_version" || die "Could not load $MM_version: $@";
	eval "use Test::Manifest 1.21" 
		if -e File::Spec->catfile( qw(t test_manifest) );
	WriteMakefile( %WriteMakefile );
	}


no warnings;
__PACKAGE__;
