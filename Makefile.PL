# $Id$
use ExtUtils::MakeMaker;

{
no warnings;

*ExtUtils::MM_Any::test_via_harness = sub
	{
	my($self, $perl, $tests) = @_;

	return qq|\t$perl "-MTest::Manifest" | .
		qq|"-e" "run_t_manifest(\$(TEST_VERBOSE), '\$(INST_LIB)', | .
		qq|'\$(INST_ARCHLIB)')"\n|;
	};
}

my $script_name = 'scriptdist';

WriteMakefile(
		'NAME'      => $script_name,
        'VERSION'   => '0.12',

		'EXE_FILES' =>  [ $script_name ],
            
		'PREREQ_PM' => {
                },

		'MAN1PODS'  => {
			$script_name => "\$(INST_MAN1DIR)/$script_name.1",
			},

		clean => { FILES => "*.bak $script_name-* " .
			"t/test_home_dir/test_script.d" },
		);
        
1;
