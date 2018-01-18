# Copyright 2018 Jeffrey Kegler
# This file is part of Marpa::R2.  Marpa::R2 is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::R2 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::R2.  If not, see
# http://www.gnu.org/licenses/.

package Marpa::R2::Display;

use 5.010001;
use strict;
use warnings;
use Fatal qw(open close);
use YAML::XS;
use Data::Dumper;    # for debugging
use Carp;

package Marpa::R2::Display::Internal;

use English qw( -no_match_vars );

sub Marpa::R2::Display::new {
    my ($class) = @_;
    my $self = {};
    $self->{displays}         = {};
    $self->{ignored_displays} = [];
    return bless $self, $class;
} ## end sub Marpa::R2::Display::new

@Marpa::R2::Display::Internal::DISPLAY_SPECS = qw(
    start-after-line end-before-line perltidy normalize-whitespace name
    remove-display-indent
    remove-blank-last-line
    partial flatten inline
    ignore
);

sub Marpa::R2::Display::read {
    my ( $self, $data_arg, $file_name ) = @_;
    my @lines;
    GET_LINES: {
        if ( not ref $data_arg ) {
            $file_name //= $data_arg;
            open my $fh, q{<}, $data_arg;
            @lines = <$fh>;
            close $fh;
            last GET_LINES;
        } ## end if ( not ref $data_arg )
        $file_name //= q{?};
        @lines = split /\n/xms, ${$data_arg};
    } ## end GET_LINES:

    chomp @lines;
    my @verbatim_lines;
    my $in_pod      = 0;
    my $in_verbatim = 0;
    my $in_begin;
    POD_LINE: for my $zero_based_line ( 0 .. $#lines ) {
        my $line = $lines[$zero_based_line];
        if ( $in_pod and $line =~ /\A=cut/xms ) {
            $in_pod      = 0;
            $in_verbatim = 0;
            $in_begin    = undef;
            next POD_LINE;
        } ## end if ( $in_pod and $line =~ /\A=cut/xms )
        if ( not $in_pod and $line =~ /\A=[a-zA-Z]/xms ) {
            $in_pod = 1;
        }
        next POD_LINE if not $in_pod;

        # at this point out $in_pod indicates if we are
        # in a pod sequence
        if ( $in_pod and not $in_begin and $line =~ /\A=begin\s+(.*)/xms ) {
            my $begin_identifier = $1;
            if ( $begin_identifier !~ /\A:/xms ) {
                $in_begin = $begin_identifier;
            }
        } ## end if ( $in_pod and not $in_begin and $line =~ ...)
        if ( $in_begin and $line =~ /\A=end\s+(.*)/xms ) {
            my $begin_identifier = $1;
            if ( $begin_identifier eq $in_begin ) {
                $in_begin = undef;
            }
        } ## end if ( $in_begin and $line =~ /\A=end\s+(.*)/xms )

        # Don't look for verbatim paragraph inside begin
        next POD_LINE if $in_begin;

        # Is this the start of a verbatim paragraph?
        if ( not $in_verbatim and $line =~ /\A[ \t]/xms ) {
            $in_verbatim = 1;
        }
        if ( $in_verbatim and $line =~ /\A[ \t]*\z/xms ) {
            $in_verbatim = 0;
        }
        if ($in_verbatim) {
            $verbatim_lines[ $zero_based_line + 1 ] = $line;
        }
    } ## end for my $zero_based_line ( 0 .. $#lines )
    LINE: for my $zero_based_line ( 0 .. $#lines ) {
        my $line = $lines[$zero_based_line];

        my $display_spec;
        my $display_spec_line_number = $zero_based_line + 1;
        if ( $line =~ /^[#] \s+ Marpa::R2[:][:]Display/xms ) {

            my $yaml = q{};
            while ( ( my $yaml_line = $lines[ ++$zero_based_line ] )
                =~ /^[#]/xms )
            {
                $yaml .= "$yaml_line\n";
            }
            if ( $yaml =~ / \S /xms ) {
                $yaml =~ s/^ [#] \s? //xmsg;
                local $main::EVAL_ERROR = undef;
                my $eval_ok =
                    eval { $display_spec = YAML::XS::Load($yaml); 1 };
                if ( not $eval_ok ) {
                    say {*STDERR} $main::EVAL_ERROR
                        or Carp::croak("Cannot print: $ERRNO");
                    say {*STDERR}
                        "Fatal error in YAML Display spec at $file_name, line "
                        . ( $display_spec_line_number + 1 )
                        or Carp::croak("Cannot print: $ERRNO");
                } ## end if ( not $eval_ok )
            } ## end if ( $yaml =~ / \S /xms )
        } ## end if ( $line =~ /^[#] \s+ Marpa::R2[:][:]Display/xms )

        if ( $line =~ /^[=]for \s+ Marpa::R2[:][:]Display/xms ) {

            my $yaml = q{};
            while (
                ( my $yaml_line = $lines[ ++$zero_based_line ] ) =~ /\S/xms )
            {
                $yaml .= "$yaml_line\n";
            }
            if ( $yaml =~ / \S /xms ) {
                local $main::EVAL_ERROR = undef;
                my $eval_ok =
                    eval { $display_spec = YAML::XS::Load($yaml); 1 };
                if ( not $eval_ok ) {
                    say {*STDERR} $main::EVAL_ERROR
                        or Carp::croak("Cannot print: $ERRNO");
                    say {*STDERR}
                        "Fatal error in YAML Display spec at $file_name, line "
                        . ( $display_spec_line_number + 1 )
                        or Carp::croak("Cannot print: $ERRNO");
                } ## end if ( not $eval_ok )
            } ## end if ( $yaml =~ / \S /xms )
        } ## end if ( $line =~ /^[=]for \s+ Marpa::R2[:][:]Display/xms)

        next LINE if not defined $display_spec;

        SPEC: for my $spec ( keys %{$display_spec} ) {
            next SPEC
                if $spec ~~ \@Marpa::R2::Display::Internal::DISPLAY_SPECS;
            say {*STDERR}
                qq{Warning: Unknown display spec "$spec" in $file_name, line $display_spec_line_number}
                or Carp::croak("Cannot print: $ERRNO");
        } ## end for my $spec ( keys %{$display_spec} )

        my $content;
        my $content_start_line;
        my $content_end_line;
        if ( defined( my $end_pattern = $display_spec->{'end-before-line'} ) )
        {
            my $end_pat = qr/$end_pattern/xms;
            if (defined(
                    my $start_pattern = $display_spec->{'start-after-line'}
                )
                )
            {
                my $start_pat = qr/$start_pattern/xms;
                PRE_CONTENT_LINE: while (1) {
                    my $pre_content_line = $lines[ ++$zero_based_line ];
                    if ( not defined $pre_content_line ) {
                        say {*STDERR}
                            qq{Warning: Pattern "$start_pattern" never found, },
                            qq{started looking at $file_name, line $display_spec_line_number}
                            or Carp::croak("Cannot print: $ERRNO");
                        return $self;
                    } ## end if ( not defined $pre_content_line )
                    last PRE_CONTENT_LINE
                        if $pre_content_line =~ /$start_pat/xms;
                } ## end while (1)
            } ## end if ( defined( my $start_pattern = $display_spec->{...}))

            CONTENT_LINE: while (1) {
                my $content_line = $lines[ ++$zero_based_line ];
                if ( not defined $content_line ) {
                    say {*STDERR}
                        qq{Warning: Pattern "$end_pattern" never found, },
                        qq{started looking at $file_name, line $display_spec_line_number}
                        or Carp::croak("Cannot print: $ERRNO");
                } ## end if ( not defined $content_line )
                last CONTENT_LINE if $content_line =~ /$end_pat/xms;
                $content .= "$content_line\n";
                $content_end_line = $zero_based_line + 1;
                $content_start_line //= $zero_based_line + 1;
            } ## end while (1)
        } ## end if ( defined( my $end_pattern = $display_spec->{...}))

        if ( not defined $content ) {
            CONTENT_LINE: while (1) {
                my $content_line = $lines[ ++$zero_based_line ];
                if ( not defined $content_line ) {
                    say {*STDERR}
                        q{Warning: Pattern "Marpa::R2::Display::End" never found,}
                        . qq{started looking at $file_name, line $display_spec_line_number}
                        or Carp::croak("Cannot print: $ERRNO");
                    return $self;
                } ## end if ( not defined $content_line )
                last CONTENT_LINE
                    if $content_line
                        =~ /^[=]for \s+ Marpa::R2[:][:]Display[:][:]End\b/xms;
                last CONTENT_LINE
                    if $content_line
                        =~ /^[#] \s* Marpa::R2[:][:]Display[:][:]End\b/xms;
                $content .= "$content_line\n";
                $content_end_line = $zero_based_line + 1;
                $content_start_line //= $zero_based_line + 1;
            } ## end while (1)
        } ## end if ( not defined $content )

        $content //= '!?! No Content Found !?!';

        my $display_spec_name = $display_spec->{name};
        my $ignore            = $display_spec->{ignore};
        if ( not $display_spec_name and not $ignore ) {
            say {*STDERR} q{Warning: Unnamed display }
                . qq{at $file_name, line $display_spec_line_number}
                or Carp::croak("Cannot print: $ERRNO");
            next LINE;
        } ## end if ( not $display_spec_name and not $ignore )

        $display_spec->{filename}           = $file_name;
        $display_spec->{display_spec_line}  = $display_spec_line_number;
        $display_spec->{content}            = $content;
        $display_spec->{content_start_line} = $content_start_line;
        $display_spec->{content_end_line}   = $content_end_line;
        $display_spec->{line}               = $content_start_line
            // $display_spec_line_number;

        $verbatim_lines[$_] = undef
            for $display_spec->{line} .. $display_spec->{content_end_line};

        if ( not $ignore ) {
            push @{ $self->{displays}->{$display_spec_name} }, $display_spec;
            next LINE;
        }

        push @{ $self->{ignored_displays} }, $display_spec;

    } ## end for my $zero_based_line ( 0 .. $#lines )

    $self->{verbatim_lines}->{$file_name} = \@verbatim_lines;

    return $self;

} ## end sub Marpa::R2::Display::read

1;
