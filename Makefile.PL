use ExtUtils::MakeMaker;

require 5.006;

eval "use Test::Manifest 1.14";

my $script_name = 'scriptdist';

WriteMakefile(
	'NAME'      => $script_name,
	'ABSTRACT'  => 'Make a Perl dist around a script',

	'VERSION'   => '0.21',
	'LICENSE'   => 'perl',
	'AUTHOR'    => 'brian d foy <bdfoy@cpan.org>',

	'EXE_FILES' =>  [ $script_name ],

	'PREREQ_PM' => {
		'Test::More' => '0',
		},

	'MAN1PODS'  => {
		$script_name => "\$(INST_MAN1DIR)/$script_name.1",
		},

	clean => { FILES => "*.bak $script_name-* " .
		"t/test_home_dir/test_script.d" },
	);

1;
