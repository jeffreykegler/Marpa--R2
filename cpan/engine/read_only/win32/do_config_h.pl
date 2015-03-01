#!env perl
# Copyright 2015 Jeffrey Kegler
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# This script will generate config.h
#
# It is assumed that current working directory is a build directory, i.e.
# the target directory specified on the command-line when you
# execute: cp_libmarpa.sh target_directory
#
use feature 'say';
use English qw/-no_match_vars/;
use Config;
use File::Slurp qw/read_file/;
use IPC::Cmd qw/run/;
use Module::Load qw/load/;
use POSIX qw/EXIT_SUCCESS EXIT_FAILURE/;
use Getopt::Long;

our %PERL_AUTOCONF_OS = map { $_ => 1 } qw( MSWin32 openbsd solaris sunos midnightbsd );

my $MARPA_DEBUG       = $ENV{MARPA_DEBUG}                 || 0;
my $USE_PERL_AUTOCONF = $ENV{MARPA_USE_PERL_AUTOCONF}     || ( $PERL_AUTOCONF_OS{$^O} // 0 );
my $CC                = $ENV{CC} || $Config{cc}           || 'cc';
my $CCFLAGS           = $ENV{CCFLAGS} || $Config{ccflags} || '';
my $SH                = $ENV{SH} || $Config{sh}           || '';
my $OBJ_EXT           = $ENV{OBJ_EXT} || $Config{obj_ext} || '.o';

GetOptions ('marpa_debug!'       => \$MARPA_DEBUG,
            'use_perl_autoconf!' => \$USE_PERL_AUTOCONF,
            'cc=s'               => \$CC,
            'ccflags=s'          => \$CCFLAGS,
            'sh=s'               => \$SH,
            'obj_ext=s'          => \$OBJ_EXT,
            'help!'              => \$help) ||
die "Error in command-line arguments";

if ($help) {
  usage();
  exit(EXIT_SUCCESS);
}

if ($USE_PERL_AUTOCONF) {
    load Config::AutoConf || die "Please install Config::AutoConf module";
}

my $rc = do_config_h();

exit($rc ? EXIT_SUCCESS : EXIT_FAILURE);

sub do_config_h {

  $ENV{CC} = $CC;
  $ENV{CCFLAGS} = $CCFLAGS;
  $ENV{OBJ_EXT} = $OBJ_EXT;

    # If current directory exists and contains a stamp file more recent than an eventual config.h
    # we are done.
    if (-e 'config.h' && -e 'stamp-h1' && up_to_date( 'config.h', 'stamp-h1' )) {
      printf "%s is up-to-date v.s. %s. Remove one of them to force a new %s generation\n", 'config.h', 'stamp-h1', 'config.h';
      return 1;
    }

    unlink('config.h');
    unlink('stamp-h1');

    # Otherwise, redo config.h
    if (! $USE_PERL_AUTOCONF) {

            # This is only necessary for GNU autoconf, which is aggressive
            # about looking for things to update

            # Some files should NEVER be updated in this directory, by
            # make or anything else.  If for some reason they are
            # out of date, stamp them up to date

            my @m4_files         = glob('m4/*.m4');
            my $configure_script = 'configure';
        
            if (not up_to_date( [ 'configure.ac', @m4_files ], 'aclocal.m4' ) )
            {
                utime time(), time(), 'aclocal.m4';
            }
            if (not up_to_date(
                    [ 'configure.ac', 'Makefile.am', 'aclocal.m4' ],
                    'Makefile.in'
                )
                )
            {
                utime time(), time(), 'Makefile.in';
            } ## end if ( not up_to_date( [ 'configure.ac', 'Makefile.am'...]))
            if (not up_to_date(
                    [ 'configure.ac',    'aclocal.m4' ],
                    [ $configure_script, 'config.h.in' ]
                )
                )
            {
                utime time(), time(), $configure_script;
                utime time(), time(), 'config.h.in';
            } ## end if ( not up_to_date( [ 'configure.ac', 'aclocal.m4'...]))
        
	    say join q{ }, "Doing config.h with configure"
		or die "print failed: $ERRNO";
            my $shell = $SH;
        
        ##no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
            $shell or die q{No Bourne shell available says $SH};
        ##use critic
    }
    
    my $original_cflags = $ENV{CFLAGS};
    local $ENV{CFLAGS};
    $ENV{CFLAGS} = $original_cflags if defined $original_cflags;

    # We need PIC, but do not want the overhead of building the shared library
    my @configure_command_args = qw(--with-pic --disable-shared);

    my @debug_flags = ();
    if ( $MARPA_DEBUG ) {
        if ( defined $ENV{LIBMARPA_CFLAGS} ) {
            $ENV{CFLAGS} = $ENV{LIBMARPA_CFLAGS};
        }
        push @debug_flags, '-DMARPA_DEBUG=1';
        push @debug_flags, '-fno-inline', '-Wno-inline' if ($CC eq 'gcc');
        push @configure_command_args,
            'MARPA_DEBUG_FLAG=' . ( join q{ }, @debug_flags );
    } ## end if ( $MARPA_DEBUG )
        
    if ($USE_PERL_AUTOCONF) {

        my $libmarpa_version = read_file('LIB_VERSION');
        chomp $libmarpa_version;
        my @libmarpa_version = split /[.]/xms, $libmarpa_version;

        #
        ## C.f. http://fr.slideshare.net/hashashin/building-c-and-c-libraries-with-perl
        #
        my @c = qw/marpa_ami.c marpa_avl.c marpa.c
            marpa_codes.c marpa_obs.c marpa_tavl.c/;
        if (! -r 'config.h') {
            #
            ## Because Config::AutoConf can only generate #define/#undef
            ## stubs, we write our config.h with these stubs, our config.h
            ## will then include a generated config_from_autoconf.h
            #
	    say join q{ }, "Doing config.h with Config::AutoConf"
		or die "print failed: $ERRNO";
            open my $config_fh, '>>', 'config.h' || die "Cannot open config.h, $!\n";
            my $ac = Config::AutoConf->new();
            my $inline_ok = 0;
            {
                $ac->msg_checking('inline');
                my $program = $ac->lang_build_program("static inline int testinline() {return 1;}\n", 'testinline');
                $inline_ok = $ac->compile_if_else($program);
                $ac->msg_result($inline_ok ? 'yes' : 'no');
            }
            my $inline = '';
            if (! $inline_ok) {
                foreach (qw/__inline__ __inline/) {
                    my $candidate = $_;
                    $ac->msg_checking($candidate);
                    my $program = $ac->lang_build_program("static $candidate int testinline() {return 1;}\n", 'testinline');
                    my $rc = $ac->compile_if_else($program);
                    $ac->msg_result($rc ? 'yes' : 'no');
                    if ($rc) {
                        $inline = $candidate;
                        last;
                    }
                }
            } else {
                $inline = 'inline';
            }
            if ($inline) {
                print {$config_fh} <<INLINEHOOK;
#ifndef __CONFIG_WITH_STUBS_H
#ifndef __cplusplus
#define inline $inline
#endif
#include "config_from_autoconf.h"
#endif /* __CONFIG_WITH_STUBS_H */
INLINEHOOK
            } else {
                print {$config_fh} <<INLINEHOOK;
#ifndef __CONFIG_WITH_STUBS_H
#ifndef __cplusplus
/* #undef inline */
#endif
#include "config_from_autoconf.h"
#endif /* __CONFIG_WITH_STUBS_H */
INLINEHOOK
            }

            # Config::Autoconf mistakes 0 for undef, so these must be done explicitly
            say {$config_fh} join q{ }, '#define MARPA_LIB_MAJOR_VERSION', $libmarpa_version[0];
            say {$config_fh} join q{ }, '#define MARPA_LIB_MINOR_VERSION', $libmarpa_version[1];
            say {$config_fh} join q{ }, '#define MARPA_LIB_MICRO_VERSION', $libmarpa_version[2];

            close($config_fh);
            $ac = Config::AutoConf->new();
            my $sizeof_int = $ac->check_sizeof_type('int');
            if ($sizeof_int < 4) {
                die "Marpa requires that int be at least 32 bits -- on this system that is not the case";
            }

            $ac->check_stdc_headers;
            $ac->check_default_headers();

            # This check was to prepare for Perl's 64-bit pseudo-UTF8 characters inside the SLIF.
            # It needs to be rethought.
            #
            # if (!$ac->check_type('unsigned long long int')) {
                # die "Marpa requires that unsigned long long int is supported by your compiler";
            # }

            $ac->define_var('PACKAGE', "\"libmarpa\"");
            $ac->define_var('PACKAGE_BUGREPORT', "\"http://rt.cpan.org/NoAuth/Bugs.html?Dist=Marpa\"");
            $ac->define_var('PACKAGE_NAME', "\"libmarpa\"");
            $ac->define_var('PACKAGE_STRING', "\"libmarpa $libmarpa_version[0].$libmarpa_version[1].$libmarpa_version[2]\"");
            $ac->define_var('PACKAGE_TARNAME', "\"libmarpa\"");
            $ac->define_var('PACKAGE_URL', "\"\"");
            $ac->define_var('PACKAGE_VERSION', "\"$libmarpa_version\"");
            $ac->define_var('PACKAGE_STRING', "\"$libmarpa_version\"");
            $ac->write_config_h('config_from_autoconf.h');
	    #
	    # Touch $dist_stamp_file
	    #
	    if (! open(my $stamp, '>', 'stamp-h1')) {
		warn "Cannot update $dist_stamp_file";
	    } else {
		close($stamp);
	    }
		
        }

        my @o = map {s/\.c$/$OBJ_EXT/; $_} @c;
        if (! -r 'Makefile.PL') {
            open my $makefile_pl_fh, '>', 'Makefile.PL';
            my $CCFLAGS = @debug_flags ? "$CCFLAGS} @debug_flags" : '';
            print {$makefile_pl_fh} "
use ExtUtils::MakeMaker;
WriteMakefile(VERSION        => \"$libmarpa_version\",
              XS_VERSION     => \"$libmarpa_version\",
              NAME           => 'libmarpa',
              OBJECT         => '@o',
              CCFLAGS        => '$CCFLAGS',
              LINKTYPE       => 'static');
";
            close $makefile_pl_fh;
            die 'Making Makefile: perl Failure'
                if not run( command => [$^X, 'Makefile.PL'], verbose => 1 );
        }
    } else {
            my $shell = $SH;
            my $configure_script = 'configure';
	    say join q{ }, "Running command:", $shell, $configure_script,
	    @configure_command_args
		or die "print failed: $ERRNO";
            if (not run(
                    command => [ $shell, $configure_script, @configure_command_args ],
                    verbose => 1
                )
                )
            {
                say {*STDERR} "Failed: $configure_script"
                    or die "say failed: $ERRNO";
                say {*STDERR} "Current directory: $build_dir"
                    or die "say failed: $ERRNO";
                die 'Cannot run libmarpa configure';
            } ## end if ( not run( command => [ $shell, $configure_script...]))
        
    }

    return 1;

} ## end sub do_libmarpa_prepare_build

#
# Copy/little adaptation of /usr/share/perl5/Module/Build/Base.pm:up_to_date()
#
sub up_to_date {
  my ($source, $derived) = @_;
  $source  = [$source]  unless ref $source;
  $derived = [$derived] unless ref $derived;

  # empty $derived means $source should always run
  return 0 if @$source && !@$derived || grep {not -e} @$derived;

  my $most_recent_source = time / (24*60*60);
  foreach my $file (@$source) {
    unless (-e $file) {
      warn "Can't find source file $file for up-to-date check";
      next;
    }
    $most_recent_source = -M _ if -M _ < $most_recent_source;
  }

  foreach my $derived (@$derived) {
    return 0 if -M $derived > $most_recent_source;
  }
  return 1;
}

sub usage {
  print STDERR <<USAGE;

$^X $0 [options] where options can be:

  --marpa_debug       Boolean. Default value: $MARPA_DEBUG.
  --use_perl_autoconf Boolean. Default value: $USE_PERL_AUTOCONF
  --cc=...            String.  Default value: $CC
  --ccflags=...       String.  Default value: $CCFLAGS
  --sh=...s           String.  Default value: $SH
  --obj_ext=...       String.  Default value: $OBJ_EXT
  --help              Boolean. This help -;

USAGE
}
