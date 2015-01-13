#!/usr/bin/perl
# Copyright 2015 Jeffrey Kegler
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

use 5.010;
use strict;
use warnings;

use LWP::UserAgent;
use URI::URL;
use HTML::LinkExtor;
use English qw( -no_match_vars );
use Fatal qw(open close);
use CPAN;
use Getopt::Long;

my $verbose = 0;
Carp::croak("usage: $PROGRAM_NAME [--verbose=[0|1|2] [distribution]")
    if not Getopt::Long::GetOptions( 'verbose=i' => \$verbose );

use constant OK => 200;

my $most_recent_distribution = pop @ARGV;
if ( not $most_recent_distribution ) {
    my @distributions =
        grep     {/\A Marpa [-] R2 [-] \d /xms}
        sort map { $_->[2] }
        CPAN::Shell->expand( 'Author', 'JKEGL' )->ls( 'Marpa-R2-*', 2 );
    $most_recent_distribution = pop @distributions;
    $most_recent_distribution =~ s/\.tar\.gz$//xms;
} ## end if ( not $most_recent_distribution )

my $cpan_base      = 'http://search.cpan.org';
my $marpa_doc_base = $cpan_base . '/~jkegl/' . "$most_recent_distribution/";

if ($verbose) {
    print "Starting at $marpa_doc_base\n"
        or Carp::croak("Cannot print: $ERRNO");
}

$OUTPUT_AUTOFLUSH = 1;

my @doc_urls = ();

{
    my $p  = HTML::LinkExtor->new();
    my $ua = LWP::UserAgent->new;

    # Request document and parse it as it arrives
    my $response = $ua->request( HTTP::Request->new( GET => $marpa_doc_base ),
        sub { $p->parse( $_[0] ) } );

    my $page_response_status_line = $response->status_line;
    if ( $response->code != OK ) {
        Carp::croak( 'PAGE: ', $page_response_status_line, q{ },
            $marpa_doc_base );
    }

    my @links =
        map { $_->[2] }
        grep { $_->[0] eq 'a' and $_->[1] eq 'href' and $_->[2] !~ /^[#]/xms }
        $p->links();

    @doc_urls = grep {/^pod\//xms} @links;
}

my %url_seen = ();

my $at_col_0 = 1;
PAGE: for my $url (@doc_urls) {
    $url = $marpa_doc_base . $url;
    print "Examining document $url" or Carp::croak("Cannot print: $ERRNO");
    $at_col_0 = 0;

    my $p  = HTML::LinkExtor->new();
    my $ua = LWP::UserAgent->new;

    # Request document and parse it as it arrives
    my $response = $ua->request( HTTP::Request->new( GET => $url ),
        sub { $p->parse( $_[0] ) } );

    my $page_response_status_line = $response->status_line;
    if ( $response->code != OK ) {
        say 'PAGE: ', $page_response_status_line, q{ }, $url
            or Carp::croak("Cannot print: $ERRNO");
        next PAGE;
    }

    my @links =
        map { $_->[2] }
        grep { $_->[0] eq 'a' and $_->[1] eq 'href' } $p->links();

    LINK: for my $link (@links) {

        given ($link) {
            when (/\A\//xms) {
                $link = 'http://search.cpan.org' . $link;
            }
            when (/\A[#]/xms) {
                $link = $url . $link;
            }
        } ## end given

        if ( $url_seen{$link}++ ) {
            if ( $verbose >= 2 ) {
                say {*STDERR} "Already tried $link"
                    or Carp::croak("Cannot print: $ERRNO");
                $at_col_0 = 1;
            }
            next LINK;
        } ## end if ( $url_seen{$link}++ )

        if ( $verbose > 1 ) {
            $at_col_0 or print "\n" or Carp::croak("Cannot print: $ERRNO");
            say {*STDERR} "Trying $link"
                or Carp::croak("Cannot print: $ERRNO");
            $at_col_0 = 1;
        } ## end if ( $verbose > 1 )

        my $link_response =
            $ua->request( HTTP::Request->new( GET => $link ) );

        if ( $link_response->code != OK ) {
            $at_col_0 or print "\n" or Carp::croak("Cannot print: $ERRNO");
            say 'FAIL: ', $link_response->status_line, q{ }, $link
                or Carp::croak("Cannot print: $ERRNO");
            $at_col_0 = 1;
            next LINK;
        } ## end if ( $link_response->code != OK )

        if ( not $verbose ) {
            print {*STDERR} q{.}
                or Carp::croak("Cannot print: $ERRNO");
            $at_col_0 = 0;
        }

        if ($verbose) {
            $at_col_0 or print "\n" or Carp::croak("Cannot print: $ERRNO");
            my $uri = $link_response->base();
            say {*STDERR} "FOUND $link"
                or Carp::croak("Cannot print: $ERRNO");
            say {*STDERR} "  uri: $uri"
                or Carp::croak("Cannot print: $ERRNO");
            if ( $verbose >= 3 ) {
                for my $redirect ( $link_response->redirects() ) {
                    my $redirect_uri = $redirect->base();
                    say {*STDERR} "  redirect: $redirect_uri"
                        or Carp::croak("Cannot print: $ERRNO");
                }
            } ## end if ( $verbose >= 3 )
            $at_col_0 = 1;
        } ## end if ($verbose)

    } ## end for my $link (@links)

    $at_col_0 or print "\n" or Carp::croak("Cannot print: $ERRNO");
    $at_col_0 = 1;

    if ($verbose) {
        say " PAGE: $page_response_status_line: $url"
            or Carp::croak("Cannot print: $ERRNO");
        $at_col_0 = 1;
    }

} ## end for my $url (@doc_urls)
