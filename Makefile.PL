use ExtUtils::MakeMaker 6.64;

require 5.010;

eval "use Test::Manifest 1.21";

my $script_name = 'scriptdist';

WriteMakefile(
	'NAME'      => $script_name,
	'ABSTRACT'  => 'Make a Perl dist around a script',

	'VERSION'   => '0.23',
	'LICENSE'   => 'perl',
	'AUTHOR'    => 'brian d foy <bdfoy@cpan.org>',

	'EXE_FILES' =>  [ $script_name ],

	'PREREQ_PM' => {
		'Test::More' => '0.95',
		'File::Path' => '2.00',
		},

	'META_MERGE' => {
		resources => {
			repository => 'https://github.com/briandfoy/scriptdist',
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
