use Test::More tests => 43;

use Cwd;
use File::Basename qw(basename);
use File::Spec;

my $script_path = 'blib/script/scriptdist';
my $script_name = basename( $script_path );

my $target_script = 'test_script';
my $options       = $target_script;

my $Home      = $ENV{HOME} = File::Spec->catfile( 
	getcwd(), 't', 'test_home_dir');

my $Templates = File::Spec->catfile( $Home, "." . $script_name        );
my $Config    = File::Spec->catfile( $Home, "." . $script_name . "rc" );
my $program   = File::Spec->catfile( $Home, $target_script            );

my $Makefile  = File::Spec->catfile( $Templates, 'Makefile.PL' );
my $Install   = File::Spec->catfile( $Templates, 'INSTALL' );

# ensure all of the files are in place
ok( -e $script_path, 'scriptdist exists'           );
ok( -x $script_path, 'scriptdist is executable'    );
ok( -e $program,     'Target program exists'       );
ok( -e $Config,      'Config file exists'          );
ok( -d $Templates,   'Template directory exists'   );
ok( -f $Makefile,    'Template Makefile.PL exists' );
ok( -f $Install,     'Template INSTALL exists'     );

# run scriptdist

my $changed = chdir $Home;
ok( $changed, 'Changed to home directory' );

system "../../$script_path", $options;

# ensure scriptdist created files

my @Files = ( qw(Makefile.PL Changes MANIFEST MANIFEST.SKIP INSTALL
		.cvsignore .releaserc), 
	$target_script,
	map { File::Spec->catfile( 't', $_ ) } 
		qw(compile.t pod.t prereq.t test_manifest)
	);
	
my $program_dir   = "$target_script.d";
my $t_dir         = File::Spec->catfile( $program_dir, 't' );

# ensure directories exist
ok( -d $program_dir, 'Target directory exists' );
ok( -d $t_dir,       'Test directory exists'   );

# ensure files exist
foreach my $file ( map { File::Spec->catfile( $program_dir, $_ ) }
	@Files  )
	{
	ok( -e $file, "File $file exists" );
	}

#ensure template files have replacements
my $install = File::Spec->catfile( $program_dir, 'INSTALL' );
my $opened = open my($fh), $install;
ok( $opened, "Opened replacements test file\n" );
my $data = do { local $/; <$fh> };

  like( $data, qr/file for \Q$target_script/, 'Replacement test has script name' );
  like( $data, qr/version \Q0.10/, 'Replacement test has version' );
unlike( $data, qr/%%SCRIPTDIST.*?%%/, 'Replacement test has no more placeholders' );

# ensure we are in the right directory before we delete files
$changed = chdir $program_dir;
ok( $changed, 'Change to program directory' ); 

SKIP: {
	my $cwd = getcwd();
	#diag( "cwd is $cwd, program dir is $program_dir\n" );
	
	skip "I do not think I am in the right directory!", scalar @Files + 3, 
			unless $changed &&
		like( $cwd, qr/\Q$program_dir\E$/, 'Path has the new directory' );
	
	diag( "Cleaning up...\n" );
	
	foreach my $file ( @Files )
		{
		#diag( "\tunlinking file $file\n" );
		ok( unlink $file, "Removed $file" );
		}
	
	$changed = chdir '..';
	ok( $changed, 'Moved above program dir' );
	$cwd = getcwd();
	#diag( "cwd is $cwd, program dir is $program_dir\n" );
	
	foreach my $dir ( $t_dir, $program_dir )
		{
		#diag( "\tremoving dir $dir\n" );
		ok( rmdir $dir, "Removed $dir" ) or diag( "Could not remove [$dir]: $!" );
		}
	}
