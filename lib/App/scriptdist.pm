#!/usr/bin/perl
use utf8;
use v5.10;

use strict;
use warnings;

use vars qw( %Content $VERSION );

use Cwd;
use ExtUtils::Command;
use ExtUtils::Manifest;
use File::Basename qw(basename);
use File::Find qw(find);
use File::Spec;
use FindBin ();

$VERSION = '0.23_01';

my $Quiet        = $ENV{SCRIPTDIST_DEBUG} || 0;  # print progress messages
print "Quiet is $Quiet\n";
my $Name         = $FindBin::Script;
my $Home         = $ENV{HOME} || '';

print "Home directory is $Home\n" unless $Quiet;

my $Rc_directory = File::Spec->catfile( $Home, "." . $Name );
print "RC directory is $Rc_directory\n" unless $Quiet;
my $Config_file  = File::Spec->catfile( $Home, "." . $Name . "rc" );

warn <<"HERE" unless $Home ne '';
The environment variable HOME has no value, so I will look in
the current directory for $Rc_directory and $Config_file. Set
the HOME environment variable to choose another directory.
HERE

my $Dir_sep      = do {
	if(    $^O =~ m/MSWin32/ ) { '\\' }
	elsif( $^O =~ m/Mac/  )    { ":"  }
	else                       { '/'  }
	};

=head1 NAME

scriptdist - create a distribution for a perl script

=head1 SYNOPSIS

	% scriptdist script.pl

=head1 DESCRIPTION

The scriptdist program takes a script file and builds, in the current
working directory, a Perl script distribution around it.  You can add
other files to the distribution once it is in place.

This script is designed to be a stand-alone program.  You do not need
any other files to use it.  However, you can create a directory named
.scriptdist in your home directory, and scriptdist will look for local
versions of template files there.  Any files in C<~/.scriptdist/t>
will show up as is in the script's t directory (until I code the parts
to munge those files).  The script assumes you have specified your
home directory in the environment variable HOME.

You can turn on optional progress and debugging messages by setting
the environment variable SCRIPTDIST_DEBUG to a true value.

=head2 The process

=over 4

=item Check for release information

The first time the scriptdist is run, or any time the scriptdist cannot
find the file C<.scriptdistrc>, it prompts for CPAN and SourceForge
developer information that it can add to the .releaserc file. (NOT
YET IMPLEMENTED)

=item Create a directory named after the script

The distribution directory is named after the script name,
with a <.d> attached.  The suffix is there only to avoid a
name conflict. You can rename it after the script is moved
into the directory.  If the directory already exists, the
script stops. You can either move or delete the directory
and start again.

=item Look for template files

The program looks in C<.scriptdistrc> for files to copy into
the target script distribution directory. After that, it
adds more files unless they already exist (i.e. the script
found them in the template directory).  The script replaces
strings matching C<%%SCRIPTDIST_FOO%%> with the internal
value of FOO.  The defined values are currently SCRIPT, which
substitutes the script name, and VERSION, whose value is
currently hard-coded at '0.10'.

While looking for files, scriptdist skips directories named
F<CVS>, F<.git>, and F<.svn>.

=item Add Changes

A bare bones Changes file

=item Create the Makefile.PL

=item Create the t directory

=item Add compile.t, pod.t, prereq.t

=item Create test_manifest

=item Copy the script into the directory

=item Run make manifest

=item Create git repo

Unless you set the C<SCRIPTDIST_SKIP_GIT>, C<scriptdist> creates
a git repo, adds everything, and does an initial import.

=back

=head2 Creating the Makefile.PL

A few things have to show up in the Makefile.PL---the name of
the script and the prerequisites modules are the most important.
Luckily, scriptdist can discover these things and fill them in
automatically.

=head1 TO DO

* add support for Module::Build (command line switch)

* Create Meta.yml file

* Copy modules into lib directory (to create module dist)

* Command line switches to turn things on and off

=head2 Maybe a good idea, maybe not

* Add a cover.t and pod coverage test?

* Interactive mode?

* automatically import into Git?

=head1 SOURCE AVAILABILITY

This source is part of a Github project.

	https://github.com/briandfoy/scriptdist

=head1 CREDITS

Thanks to Soren Andersen for putting this script through its paces
and suggesting many changes to actually make it work.

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT

Copyright © 2004-2015, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may use this program under the same terms as Perl itself.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

my $Path   = $ARGV[0];
my $Script = basename( $Path );

print "Processing $Script...\n" unless $Quiet;

my %Defaults = (
	script               => $Script,
	version              => '0.10',   # version for the copied script, not this one
	minimum_perl_version => 5,
	modules              => [],
	);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Extract included modules
if( eval "use Module::Extract::Use; 1" ) {
	my $extor = Module::Extract::Use->new;
	my $modules = $extor->get_modules_with_details( $Path );

	unless( $Quiet ) {
		say "\tFound modules\n\t\t", join "\n\t\t", map { $_->module . " => " . $_->version } @$modules;
		}

	$Defaults{modules} = $modules;
	}
elsif( ! $Quiet ) {
	say "Install Module::Extract::Use to detect prerequisites";
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Extract declared Perl version
if( eval "use Module::Extract::DeclaredMinimumPerl; 1" ) {
	my $extor = Module::Extract::DeclaredMinimumPerl->new;
	my $version = $extor->get_minimum_declared_perl( $Path );

	unless( $Quiet ) {
		say "\tFound minimum version $version";
		}

	$Defaults{minimum_perl_version} = $version;
	}
elsif( ! $Quiet ) {
	say "Install Module::Extract::DeclaredMinimumPerl to detect minimum versions";
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
content( \%Defaults );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Make directories
my $Directory = "$Script.d";
die <<"HERE" if -d $Directory;
Directory $Directory already exists! Either delete it or
move it out of the way, then rerun this program.
HERE

foreach my $dir ( map { $_, File::Spec->catfile( $_, "t" ) } $Directory ) {
	print "Making directory $dir...\n" unless $Quiet;
	mkdir $dir, 0755 or die "Could not make [$dir]: $!\n";
	}

# Copy local template files
print "RC directory is $Rc_directory\n" unless $Quiet;
print "cwd is ", getcwd, "\n";

if( -d $Rc_directory ) {
	print "Looking for local templates...\n" unless $Quiet;
	foreach my $input ( find_files( $Rc_directory ) ) {
		my( $path ) = $input =~ m/\Q$Rc_directory$Dir_sep\E(.*)/g;

		my @path = File::Spec->splitdir( $path );
		my $file = pop @path;

		if( @path ) {
			local @ARGV = File::Spec->catfile( $Directory, @path );
			ExtUtils::Command::mkpath unless -d $ARGV[0];
			}

		my $output = File::Spec->catfile( $Directory, $path );
		copy( $input, $output, \%Defaults );
		}
	}

# Add distribution files unless they already exist
FILE: foreach my $filename ( sort keys %Content ) {
	my @path = split m|\Q$Dir_sep|, $filename;

	my $file = File::Spec->catfile( $Directory, @path );

	print "Checking for file [$filename]... " unless $Quiet;
	if( -e $file ) { print "already exists\n"; next FILE }

	print "Adding file [$filename]...\n" unless $Quiet;
	open my($fh), ">", $file or do {
		warn "Could not write to [$file]: $!\n";
		next FILE;
		};

	my $contents = $Content{$filename};

	print $fh $contents;
	}

# Add the script itself
{
print "Adding [$Script]...\n";
my $dist_script = File::Spec->catfile( $Directory, $Script );

if( -e $Path ) {
	print "Copying script...\n";
	copy( $Path, $dist_script );
	}
else {
	print "Using script template...\n";

	open my $fh, ">", $dist_script;
	print { $fh } script_template( $Script );
	}
}

# Create the MANIFEST file
print "Creating MANIFEST...\n";
chdir $Directory or die "Could not change to $Directory: $!\n";
$ExtUtils::Manifest::Verbose = 0;
ExtUtils::Manifest::mkmanifest;

gitify();

print <<"HERE";
------------------------------------------------------------------
Remember to push this directory to your source control system.
In fact, why not do that right now?
------------------------------------------------------------------
HERE

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub prompt {
	my( $query ) = shift;

	print $query;

	chomp( my $reply = <STDIN> );

	return $reply;
	}

sub find_files {
	my $directory = shift;

    my @files = ();

    find( sub {
        	return unless -f $_;
        	return if $File::Find::name =~ m<(?:CVS|\.svn|\.git)>;
        	#print STDERR "Found file $File::Find::name\n";
			push( @files, $File::Find::name );
    		}, $directory
    	);

    return @files;
	}

sub copy {
	my( $input, $output, $hash ) = @_;

	print "Opening input [$input] for output [$output]\n";

	open my($in_fh),        $input  or die "Could not open [$input]: $!\n";
	open my($out_fh), ">" . $output or warn "Could not open [$output]: $!\n";

	my $count = 0;

	while( readline $in_fh ) {
		$count += s/%%SCRIPTDIST_(.*?)%%/$hash->{ lc $1 } || ''/gie;
		print $out_fh $_
		}

	print "Copied [$input] with $count replacements\n" unless $Quiet;
	}

sub gitify {
	return if $ENV{SCRIPTDIST_SKIP_GIT};
	chomp( my $git = `which git` );
	return unless length $git && -x $git;
	
	system $git, qw'init';
	system $git, qw'add .';
	system $git, qw'commit -a -m ', "Initial commit by $0 $VERSION";
	} 
	
sub script_template {
	my $script_name = shift;

	return <<"HERE";
#!/usr/bin/perl

=head1 NAME

$script_name - this script does something

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

=head1 COPYRIGHT

=cut

HERE
	}

sub content {
	my $hash = shift;

	$Content{"Changes"} =<<"CHANGES";
0.10 - @{ [ scalar localtime ] }
	+ initial distribution created with $Name
CHANGES

	$Content{"Makefile.PL"} =<<"MAKEFILE_PL";
use ExtUtils::MakeMaker 6.48;

eval "use Test::Manifest 1.21";

my \$script_name = "$$hash{script}";

WriteMakefile(
		'NAME'      => \$script_name,
		'VERSION'   => '$$hash{version}',

		'EXE_FILES' =>  [ \$script_name ],

		'PREREQ_PM' => {
@{ [
				map {
					my $v = $_->version // 0;
					"\t\t\t" . $_->module . " => '$v'\n"
				} @{$hash->{modules}}
 ] } 			},


		MIN_PERL_VERSION => $$hash{minimum_perl_version},

		clean => { FILES => "*.bak \$script_name-*" },
		);

1;
MAKEFILE_PL

	$Content{"MANIFEST.SKIP"} =<<"MANIFEST_SKIP";
\\.cvsignore
\\.git
\\.gitignore
\\.DS_Store
\\.releaserc
\\.svn
\\.git
$$hash{script}-.*
blib
CVS
Makefile\\.old
Makefile\$
MANIFEST\\.bak
MANIFEST\\.SKIP
pm_to_blib
MANIFEST_SKIP

	$Content{".releaserc"} =<<"RELEASE_RC";
cpan_user @{[ $ENV{CPAN_USER} ? $ENV{CPAN_USER} : '' ]}
RELEASE_RC

	$Content{".gitignore"} =<<"GITIGNORE";
.DS_Store
.lwpcookies
$$hash{script}-*
blib
Makefile
pm_to_blib
GITIGNORE

	$Content{"t/test_manifest"} =<<"TEST_MANIFEST";
compile.t
pod.t
TEST_MANIFEST

	$Content{"t/pod.t"} = <<"POD_T";
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if \$@;
all_pod_files_ok();
POD_T

	$Content{"t/compile.t"} = <<"COMPILE_T";
use Test::More tests => 1;

my \$file = "blib/script/$$hash{script}";

print "bail out! Script file is missing!" unless -e \$file;

my \$output = `$^X -c \$file 2>&1`;

print "bail out! Script file is missing!" unless
	like( \$output, qr/syntax OK\$/, 'script compiles' );
COMPILE_T
	}
