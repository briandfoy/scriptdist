# $Id$
use ExtUtils::MakeMaker;

sub ExtUtils::MM_Any::test_via_harness
	{
    my($self, $perl, $tests) = @_;

    return qq|	$perl "-MTest::Manifest" | .
           qq|"-e" "run_t_manifest(\$(TEST_VERBOSE), '\$(INST_LIB)', | .
           qq|'\$(INST_ARCHLIB)')"\n|;
	}

WriteMakefile(
		'NAME'      => 'scriptdist',
        'VERSION'   => '0.11',

        'EXE_FILES' =>  [ 'scriptdist' ],
            
        'PREREQ_PM' => {
				'Test::Manifest' => '0',
                },

        'MAN1PODS'  => {
                'scriptdist' => '$(INST_MAN1DIR)/scriptdist.1',
                },

        clean => { FILES => '*.bak scriptdist-*' },
        );
        
1;
